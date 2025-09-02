pipeline {
  agent { label 'build' }
  options { timestamps(); ansiColor('xterm') }

  parameters {
    choice(name: 'ACTION', choices: ['plan','apply','destroy','plan-apply'], description: '동작')
    string(name: 'BRANCH', defaultValue: 'master', description: 'Git branch')
    string(name: 'TEMPLATE_ID', defaultValue: '9005', description: '템플릿 ID')
    string(name: 'VM_DISK_SIZE', defaultValue: '300', description: '디스크 GB')
    string(name: 'VM_MEMORY', defaultValue: '32768', description: '메모리 MB')
    string(name: 'VM_CORES', defaultValue: '16', description: 'CPU 코어')
    booleanParam(name: 'ADDITIONAL_DISK_ENABLED', defaultValue: true, description: '추가 디스크 사용')
    string(name: 'ADDITIONAL_DISK_SIZE', defaultValue: '200', description: '추가 디스크 GB')
    string(name: 'ADDITIONAL_DISK_STORAGE', defaultValue: 'local-lvm', description: '추가 디스크 스토리지')
    string(name: 'VM_COUNT', defaultValue: '3', description: 'VM 수')
    string(name: 'VM_NAME_PREFIX', defaultValue: 'ubuntu-server', description: 'VM 이름 prefix')
    
    // Global GPU Passthrough parameters
    booleanParam(name: 'GLOBAL_HOSTPCI_ENABLED', defaultValue: false, description: '모든 VM에 GPU 패스스루 활성화')
    text(name: 'GLOBAL_HOSTPCI_DEVICES', defaultValue: '', description: 'JSON 형태 글로벌 GPU 디바이스 목록 (예: [{"device":"0000:01:00.0","rombar":false,"pcie":true,"xvga":false}])')
    
    // VM-specific GPU Passthrough parameters  
    text(name: 'VM_HOSTPCI_CONFIG', defaultValue: '', description: 'JSON 형태 VM별 GPU 패스스루 설정 (예: {"ubuntu-server-1":{"enabled":true,"devices":[{"device":"0000:01:00.0","rombar":false,"pcie":true}]}})')
  }
    
  environment {
    TF_IN_AUTOMATION = 'true'
    PATH = "${env.WORKSPACE}/bin:${env.PATH}"
  }

  stages {
    stage('Prepare tools') {
      steps {
        sh '''#!/usr/bin/env bash
set -Eeuo pipefail
VER=1.9.5; mkdir -p "$WORKSPACE/bin"
command -v terraform >/dev/null || {
  curl -fsSL "https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip" -o /tmp/tf.zip
  if sudo -n true 2>/dev/null; then unzip -o /tmp/tf.zip terraform -d /tmp && sudo install -m0755 /tmp/terraform /usr/local/bin/terraform
  else unzip -o /tmp/tf.zip terraform -d "$WORKSPACE/bin" && chmod +x "$WORKSPACE/bin/terraform"; fi
}
command -v jq >/dev/null || {
  if sudo -n true 2>/dev/null; then sudo apt-get update -y && sudo apt-get install -y jq
  else curl -fsSL https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -o "$WORKSPACE/bin/jq" && chmod +x "$WORKSPACE/bin/jq"; fi
}
terraform -version; jq --version
'''
      }
    }

    stage('Checkout source') {
      steps {
        dir('tf') {
          checkout([$class: 'GitSCM',
            userRemoteConfigs: [[url: 'https://github.com/pu4ro/proxmox-terraform.git']],
            branches: [[name: "*/${params.BRANCH}"]]
          ])
        }
      }
    }

    stage('Set credentials & tfvars') {
      steps {
        withCredentials([
          string(credentialsId: 'PROXMOX_API_URL',  variable: 'PROXMOX_API_URL'),
          string(credentialsId: 'PROXMOX_USER',     variable: 'PROXMOX_USER'),
          string(credentialsId: 'PROXMOX_PASSWORD', variable: 'PROXMOX_PASSWORD'),
          string(credentialsId: 'SSH_PUBKEY',       variable: 'SSH_PUBKEY')
        ]) {
          sh '''#!/usr/bin/env bash
set -Eeuo pipefail

# Parse global hostpci devices if provided
GLOBAL_HOSTPCI_DEVICES_JSON='[]'
if [ -n "${GLOBAL_HOSTPCI_DEVICES:-}" ] && [ "${GLOBAL_HOSTPCI_DEVICES:-}" != "" ]; then
  # Validate JSON format
  echo "${GLOBAL_HOSTPCI_DEVICES}" | jq . > /dev/null || {
    echo "Invalid JSON format for GLOBAL_HOSTPCI_DEVICES"
    exit 1
  }
  GLOBAL_HOSTPCI_DEVICES_JSON="${GLOBAL_HOSTPCI_DEVICES}"
fi

# Parse VM-specific hostpci config if provided
VM_HOSTPCI_CONFIG_JSON='{}'
if [ -n "${VM_HOSTPCI_CONFIG:-}" ] && [ "${VM_HOSTPCI_CONFIG:-}" != "" ]; then
  # Validate JSON format
  echo "${VM_HOSTPCI_CONFIG}" | jq . > /dev/null || {
    echo "Invalid JSON format for VM_HOSTPCI_CONFIG"
    exit 1
  }
  VM_HOSTPCI_CONFIG_JSON="${VM_HOSTPCI_CONFIG}"
fi

cat > tf/terraform.tfvars.json <<JSON
{
  "proxmox_api_url":       "${PROXMOX_API_URL}",
  "proxmox_user":          "${PROXMOX_USER}",
  "proxmox_password":      "${PROXMOX_PASSWORD}",
  "proxmox_tls_insecure":  true,

  "vm_disk_size":          ${VM_DISK_SIZE},
  "vm_memory":             ${VM_MEMORY},
  "vm_cores":              ${VM_CORES},

  "additional_disk_enabled": ${ADDITIONAL_DISK_ENABLED},
  "additional_disk_size":  ${ADDITIONAL_DISK_SIZE},
  "additional_disk_storage": "${ADDITIONAL_DISK_STORAGE}",

  "vm_count":              ${VM_COUNT},
  "vm_name_prefix":        "${VM_NAME_PREFIX}",
  "template_id":           ${TEMPLATE_ID},

  "ssh_public_key":        "${SSH_PUBKEY}",
  
  "global_hostpci_enabled": ${GLOBAL_HOSTPCI_ENABLED},
  "global_hostpci_devices": ${GLOBAL_HOSTPCI_DEVICES_JSON},
  "vm_hostpci_config":     ${VM_HOSTPCI_CONFIG_JSON}
}
JSON
jq . tf/terraform.tfvars.json
'''
        }
      }
    }

    stage('Init & Validate') {
      steps {
        dir('tf') {
          sh '''#!/usr/bin/env bash
set -Eeuo pipefail
terraform init -input=false
terraform fmt -recursive -check || true
terraform validate
'''
        }
      }
    }

    stage('Plan') {
      when { anyOf { expression { params.ACTION == 'plan' }; expression { params.ACTION == 'apply' }; expression { params.ACTION == 'plan-apply' } } }
      steps {
        dir('tf') {
          sh '''#!/usr/bin/env bash
set -Eeuo pipefail
terraform plan -input=false -out=tfplan
terraform show -no-color tfplan > ../plan.txt
'''
        }
      }
      post { always { archiveArtifacts artifacts: 'plan.txt', onlyIfSuccessful: true } }
    }
        
    stage('Manual gate') {
      when { anyOf { expression { params.ACTION == 'apply' }; expression { params.ACTION == 'plan-apply' }; expression { params.ACTION == 'destroy' } } }
      steps { input message: '실행 승인?', ok: 'Proceed' }
    }

    stage('Apply/Destroy') {
      when { anyOf { expression { params.ACTION == 'apply' }; expression { params.ACTION == 'destroy' }; expression { params.ACTION == 'plan-apply' } } }
      environment { ACTION = "${params.ACTION}" }
      steps {
        dir('tf') {
          sh '''#!/usr/bin/env bash
set -Eeuo pipefail
if [ "${ACTION}" = "destroy" ]; then
  terraform destroy -auto-approve
elif [ "${ACTION}" = "plan-apply" ]; then
  terraform apply -auto-approve tfplan
else
  terraform apply -auto-approve
fi
'''
        }
      }
    }

    stage('Outputs') {
      when { anyOf { expression { params.ACTION == 'apply' }; expression { params.ACTION == 'plan' }; expression { params.ACTION == 'plan-apply' } } }
      steps {
        dir('tf') {
          sh '''#!/usr/bin/env bash
set -Eeuo pipefail
terraform output -json > ../tfout.json || true
'''
        }
      }
      post { success { archiveArtifacts artifacts: 'tfout.json', allowEmptyArchive: true } }
    }
  }

  post { always { cleanWs(deleteDirs: true, notFailBuild: true) } }
}