output "template_id" {
  description = "Template VM ID"
  value       = proxmox_vm_qemu.template.vmid
}

output "template_name" {
  description = "Template name"
  value       = proxmox_vm_qemu.template.name
}

output "template_node" {
  description = "Node where template is stored"
  value       = proxmox_vm_qemu.template.target_node
}