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

# 사용 가능한 IP 찾기
data "external" "available_ip" {
  program = ["bash", "${path.module}/find-available-ip.sh"]
}

locals {
  vm_ip = data.external.available_ip.result.ip != null ? data.external.available_ip.result.ip : "192.168.135.100"
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = var.proxmox_tls_insecure
}

# Create VM from ubuntu-22-04-5-template
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "ubuntu-vm-terraform"
  node_name = "solutions"
  
  clone {
    vm_id = 9003
    full  = true
  }
  
  cpu {
    cores = 2
  }
  
  memory {
    dedicated = 2048
  }
  
  network_device {
    bridge = "vmbr0"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "${local.vm_ip}/24"
        gateway = "192.168.134.1"
      }
    }
    
    dns {
      servers = ["8.8.8.8"]
    }
    
    user_account {
      username = "ubuntu"
      password = "cloud1234"
      keys     = [file("~/.ssh/id_ed25519.pub")]
    }
  }
}

# 출력 값들
output "vm_ip_address" {
  value = local.vm_ip
  description = "할당된 VM IP 주소"
}

output "ssh_command" {
  value = "ssh ubuntu@${local.vm_ip}"
  description = "SSH 접속 명령"
}