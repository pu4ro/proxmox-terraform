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
    vm_id = var.template_id
    full  = true
  }
  
  cpu {
    cores = var.vm_cores
    type  = "x86-64-v2-AES"
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  # SCSI 컨트롤러를 virtio-scsi로 설정
  scsi_hardware = "virtio-scsi-single"
  
  # 기본 디스크 (클론된 디스크 크기 조정 및 iothread 설정)
  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm2"
    size         = var.vm_disk_size
    file_format  = "raw"
    iothread     = true
  }
  
  # 추가 디스크 (옵션)
  dynamic "disk" {
    for_each = var.additional_disk_enabled ? [1] : []
    content {
      interface    = "scsi1"
      datastore_id = var.additional_disk_storage
      size         = var.additional_disk_size
      file_format  = "raw"
      iothread     = true
    }
  }
  
  network_device {
    bridge = "vmbr0"
  }
  
  # PCI Device 패스스루 설정 (count.index 기반, 조건부)
  dynamic "hostpci" {
    for_each = (count.index == 0 && var.pci_device_1 != "") || (count.index == 1 && var.pci_device_2 != "") || (count.index == 2 && var.pci_device_3 != "") ? [1] : []
    content {
      device = count.index == 0 ? var.pci_device_1 : count.index == 1 ? var.pci_device_2 : count.index == 2 ? var.pci_device_3 : ""
      pcie   = var.hostpci_pcie
      rombar = var.hostpci_rombar
    }
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
      keys     = [var.ssh_public_key]
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