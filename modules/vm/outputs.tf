output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}

output "vm_status" {
  description = "VM status"
  value       = proxmox_vm_qemu.vm.status
}