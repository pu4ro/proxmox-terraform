resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  target_node = var.target_node
  clone       = var.template_name
  vmid        = var.vm_id
  
  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory
  
  disk {
    size    = var.disk_size
    type    = var.disk_type
    storage = var.storage
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  os_type = "cloud-init"
  
  ipconfig0 = "ip=${var.ip_address}/${var.subnet_mask},gw=${var.gateway}"
  
  nameserver = var.nameserver
  
  ciuser     = var.cloud_init_user
  cipassword = var.cloud_init_password
  sshkeys    = var.ssh_public_keys
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}