resource "proxmox_vm_qemu" "template" {
  name        = var.template_name
  target_node = var.target_node
  vmid        = var.template_id
  
  iso         = var.iso_file
  
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
  
  os_type = var.os_type
  
  lifecycle {
    ignore_changes = [
      network,
      iso,
    ]
  }
}

resource "null_resource" "convert_to_template" {
  depends_on = [proxmox_vm_qemu.template]
  
  provisioner "local-exec" {
    command = <<EOF
      curl -k -X POST \
        -H "Authorization: PVEAPIToken=${var.proxmox_user}:${var.proxmox_token}" \
        "${var.proxmox_api_url}/nodes/${var.target_node}/qemu/${proxmox_vm_qemu.template.vmid}/template"
    EOF
  }
  
  triggers = {
    vm_id = proxmox_vm_qemu.template.vmid
  }
}