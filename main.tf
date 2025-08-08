terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
  required_version = ">= 1.0"
}

# 각 VM마다 사용 가능한 IP 찾기
data "external" "available_ip" {
  count   = var.vm_count
  program = ["bash", "${path.module}/find-available-ip.sh", tostring(count.index)]
}

locals {
  # 각 VM에 대한 IP 맵핑
  vm_ips = {
    for i in range(var.vm_count) : 
    i => data.external.available_ip[i].result.ip != null ? data.external.available_ip[i].result.ip : "192.168.135.${30 + i}"
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = var.proxmox_tls_insecure
}

# Create VMs from ubuntu-22-04-5-template
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  count     = var.vm_count
  name      = "${var.vm_name_prefix}-${count.index + 1}"
  node_name = "solutions"
  
  clone {
    vm_id = 9005
    full  = true
  }
  
  cpu {
    cores = var.vm_cores
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  # 추가 디스크 (옵션)
  dynamic "disk" {
    for_each = var.additional_disk_enabled ? [1] : []
    content {
      interface    = "scsi1"
      datastore_id = var.additional_disk_storage
      size         = var.additional_disk_size
      file_format  = "raw"
    }
  }
  
  network_device {
    bridge = "vmbr0"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "${local.vm_ips[count.index]}/23"
        gateway = "192.168.134.1"
      }
    }
    
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
    
    user_account {
      username = "ubuntu"
      password = "cloud1234"
      keys     = [file("~/.ssh/id_ed25519.pub")]
    }
    
  }
}

# 출력 값들
output "vm_ip_addresses" {
  value = {
    for i, vm in proxmox_virtual_environment_vm.ubuntu_vm : 
    vm.name => local.vm_ips[i]
  }
  description = "할당된 VM들의 IP 주소"
}

output "vm_details" {
  value = {
    for i, vm in proxmox_virtual_environment_vm.ubuntu_vm : 
    vm.name => {
      ip = local.vm_ips[i]
      vm_id = vm.vm_id
      ssh_command = "ssh ubuntu@${local.vm_ips[i]}"
    }
  }
  description = "VM 상세 정보"
}

output "ssh_commands" {
  value = [
    for i, vm in proxmox_virtual_environment_vm.ubuntu_vm : 
    "ssh ubuntu@${local.vm_ips[i]}  # ${vm.name}"
  ]
  description = "SSH 접속 명령들"
}