variable "template_name" {
  description = "Name of the template"
  type        = string
}

variable "target_node" {
  description = "Proxmox node where the template will be created"
  type        = string
}

variable "template_id" {
  description = "Template VM ID"
  type        = number
}

variable "iso_file" {
  description = "ISO file path for template creation"
  type        = string
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

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "l26"
}

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox user for API access"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}