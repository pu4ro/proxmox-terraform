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

variable "template_id" {
  description = "복제할 템플릿 VM ID"
  type        = number
  default     = 9005
}

# GPU 패스스루 설정 (VM별 선택적 적용)
variable "vm_hostpci_config" {
  description = "VM별 GPU 패스스루 설정"
  type = map(object({
    enabled = bool
    devices = list(object({
      device = string  # GPU 디바이스 (예: "0000:01:00.0")
      rombar = optional(bool, false)  # GPU는 일반적으로 rombar를 비활성화
      pcie   = optional(bool, true)   # GPU는 일반적으로 PCIe 모드 사용
      xvga   = optional(bool, false)  # VGA 패스스루가 필요한 경우만 true
    }))
  }))
  default = {}
}

# 글로벌 GPU 패스스루 설정 (모든 VM에 적용)
variable "global_hostpci_enabled" {
  description = "모든 VM에 GPU 패스스루 활성화 여부"
  type        = bool
  default     = false
}

variable "global_hostpci_devices" {
  description = "모든 VM에 적용할 GPU 디바이스 목록"
  type = list(object({
    device = string  # GPU 디바이스 (예: "0000:01:00.0")
    rombar = optional(bool, false)  # GPU는 일반적으로 rombar를 비활성화
    pcie   = optional(bool, true)   # GPU는 일반적으로 PCIe 모드 사용
    xvga   = optional(bool, false)  # VGA 패스스루가 필요한 경우만 true
  }))
  default = []
}