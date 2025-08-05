variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "target_node" {
  description = "Proxmox node where the VM will be created"
  type        = string
}

variable "template_name" {
  description = "Name of the template to clone from"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
  default     = null
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size"
  type        = string
  default     = "20G"
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

variable "network_model" {
  description = "Network adapter model"
  type        = string
  default     = "virtio"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address for the VM"
  type        = string
}

variable "subnet_mask" {
  description = "Subnet mask (CIDR notation)"
  type        = string
  default     = "24"
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "8.8.8.8"
}

variable "cloud_init_user" {
  description = "Cloud-init user name"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Cloud-init user password"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys for cloud-init"
  type        = string
  default     = ""
}