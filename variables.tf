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
  default     = 300
}

variable "vm_memory" {
  description = "VM 메모리 (MB)"
  type        = number
  default     = 16384
}

variable "vm_cores" {
  description = "VM CPU 코어 수"
  type        = number
  default     = 16
}

# 추가 디스크 설정
variable "additional_disk_enabled" {
  description = "추가 디스크 활성화 여부"
  type        = bool
  default     = false
}

variable "additional_disk_size" {
  description = "추가 디스크 크기 (GB)"
  type        = number
  default     = 100
}

variable "additional_disk_storage" {
  description = "추가 디스크 스토리지"
  type        = string
  default     = "local-lvm"
}

# 멀티 VM 설정
variable "vm_count" {
  description = "생성할 VM 개수"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "VM 이름 접두사"
  type        = string
  default     = "ubuntu-vm"
}

variable "ssh_public_key" {
  description = "SSH 공개 키 내용"
  type        = string
}