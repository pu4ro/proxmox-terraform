variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox-server:8006/api2/json)"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox user (e.g., root@pam or terraform@pve)"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (for self-signed certificates)"
  type        = bool
  default     = true
}

# VM 설정
variable "vm_disk_size" {
  description = "VM 디스크 크기 (GB)"
  type        = number
  default     = 50
}

variable "vm_memory" {
  description = "VM 메모리 (MB)"
  type        = number
  default     = 2048
}

variable "vm_cores" {
  description = "VM CPU 코어 수"
  type        = number
  default     = 2
}