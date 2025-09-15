pipeline {
  agent { label 'build' }
  options { timestamps(); ansiColor('xterm') }

  parameters {
    choice(name: 'ACTION', choices: ['plan','apply','destroy','plan-apply'], description: '동작')
    string(name: 'BRANCH', defaultValue: 'master', description: 'Git branch')
    string(name: 'TEMPLATE_ID', defaultValue: '9007', description: '템플릿 ID')
    string(name: 'VM_DISK_SIZE', defaultValue: '400', description: '디스크 GB')
    string(name: 'VM_MEMORY', defaultValue: '65536', description: '메모리 MB')
    string(name: 'VM_CORES', defaultValue: '16', description: 'CPU 코어')
    booleanParam(name: 'VM_STARTED', defaultValue: true, description: 'Apply 시 VM 전원 켬/끔 제어')
    booleanParam(name: 'ADDITIONAL_DISK_ENABLED', defaultValue: true, description: '추가 디스크 사용')
    string(name: 'ADDITIONAL_DISK_SIZE', defaultValue: '500', description: '추가 디스크 GB')
    string(name: 'ADDITIONAL_DISK_STORAGE', defaultValue: 'local-lvm2', description: '추가 디스크 스토리지')
    string(name: 'VM_COUNT', defaultValue: '3', description: 'VM 수')
    string(name: 'VM_NAME_PREFIX', defaultValue: 'ubuntu-server', description: 'VM 이름 prefix')
    
    // PCI Passthrough (권장: Proxmox Resource Mappings)
    string(name: 'PCI_MAPPING_1', defaultValue: 'gpu01', description: '첫 번째 VM 리소스 매핑 ID (예: gpu0)')
    string(name: 'PCI_MAPPING_2', defaultValue: 'gpu03', description: '두 번째 VM 리소스 매핑 ID (예: gpu1)')
    string(name: 'PCI_MAPPING_3', defaultValue: '', description: '세 번째 VM 리소스 매핑 ID (예: gpu2)')

    // (선택) 레거시 BDF 입력 유지(현재 프로바이더에서는 매핑 권장)
    string(name: 'PCI_DEVICE_1', defaultValue: '', description: '첫 번째 VM PCI BDF (예: 0000:31:00.0)')
    string(name: 'PCI_DEVICE_2', defaultValue: '', description: '두 번째 VM PCI BDF (예: 0000:ca:00.0)')
    string(name: 'PCI_DEVICE_3', defaultValue: '', description: '세 번째 VM PCI BDF')
    booleanParam(name: 'HOSTPCI_PCIE', defaultValue: true, description: 'PCIe 모드 사용')
    booleanParam(name: 'HOSTPCI_ROMBAR', defaultValue: false, description: 'ROM BAR 사용')

    // Destroy 가속 옵션
    booleanParam(name: 'FORCE_STOP_BEFORE_DESTROY', defaultValue: true, description: 'destroy 직전 Proxmox API로 강제 stop')
    booleanParam(name: 'DESTROY_PRE_STOP_APPLY', defaultValue: false, description: 'destroy 전에 started=false 적용(사전 전원 끔)')
    booleanParam(name: 'DISABLE_REFRESH', defaultValue: true, description: 'plan/apply/destroy 시 -refresh=false 사용')
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

cat > tf/terraform.tfvars.json <<JSON
{
  "proxmox_api_url":       "${PROXMOX_API_URL}",
  "proxmox_user":          "${PROXMOX_USER}",
  "proxmox_password":      "${PROXMOX_PASSWORD}",
  "proxmox_tls_insecure":  true,

  "vm_disk_size":          ${VM_DISK_SIZE},
  "vm_memory":             ${VM_MEMORY},
  "vm_cores":              ${VM_CORES},
  "vm_started":            ${VM_STARTED},

  "additional_disk_enabled": ${ADDITIONAL_DISK_ENABLED},
  "additional_disk_size":  ${ADDITIONAL_DISK_SIZE},
  "additional_disk_storage": "${ADDITIONAL_DISK_STORAGE}",

  "vm_count":              ${VM_COUNT},
  "vm_name_prefix":        "${VM_NAME_PREFIX}",
  "template_id":           ${TEMPLATE_ID},

  "ssh_public_key":        "${SSH_PUBKEY}",
  
  "pci_mappings":          ["${PCI_MAPPING_1:-}", "${PCI_MAPPING_2:-}", "${PCI_MAPPING_3:-}"],
  "pci_mapping_1":         "${PCI_MAPPING_1:-}",
  "pci_mapping_2":         "${PCI_MAPPING_2:-}",
  "pci_mapping_3":         "${PCI_MAPPING_3:-}",

  "pci_devices":           ["${PCI_DEVICE_1:-}", "${PCI_DEVICE_2:-}", "${PCI_DEVICE_3:-}"],
  "pci_device_1":          "${PCI_DEVICE_1:-}",
  "pci_device_2":          "${PCI_DEVICE_2:-}",
  "pci_device_3":          "${PCI_DEVICE_3:-}",
  "hostpci_pcie":          ${HOSTPCI_PCIE:-true},
  "hostpci_rombar":        ${HOSTPCI_ROMBAR:-false},

  "force_stop_before_destroy": ${FORCE_STOP_BEFORE_DESTROY}
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
chmod +x scripts/*.sh 2>/dev/null || true
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
REFRESH_FLAG=""
if [ "${DISABLE_REFRESH}" = "true" ]; then REFRESH_FLAG="-refresh=false"; fi

if [ "${ACTION}" = "destroy" ]; then
  if [ "${DESTROY_PRE_STOP_APPLY}" = "true" ]; then
    echo "[info] Pre-stop apply: vm_started=false"
    terraform apply -auto-approve ${REFRESH_FLAG} -var vm_started=false || true
  fi
  terraform destroy -auto-approve ${REFRESH_FLAG}
elif [ "${ACTION}" = "plan-apply" ]; then
  terraform apply -auto-approve ${REFRESH_FLAG} tfplan
else
  terraform apply -auto-approve ${REFRESH_FLAG}
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
