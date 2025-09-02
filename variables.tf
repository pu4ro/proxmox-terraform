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

# PCI Device 패스스루 설정
variable "pci_devices" {
  description = "각 VM 인덱스별 PCI 디바이스 목록 (예: [\"0000:31:00.0\", \"0000:ca:00.0\"])"
  type        = list(string)
  default     = []
}

# Proxmox Resource Mappings (권장)
variable "pci_mappings" {
  description = "각 VM 인덱스별 Proxmox 리소스 매핑 ID 목록 (예: [\"gpu0\", \"gpu1\"])"
  type        = list(string)
  default     = []
}

# (백워드 호환) 간단한 count 기반 개별 변수
# 제공 시 위의 pci_devices가 비어 있을 때만 사용됨
variable "pci_device_1" {
  description = "첫 번째 VM에 할당할 PCI 디바이스 (예: 0000:31:00.0)"
  type        = string
  default     = ""
}

variable "pci_device_2" {
  description = "두 번째 VM에 할당할 PCI 디바이스 (예: 0000:ca:00.0)"
  type        = string
  default     = ""
}

variable "pci_device_3" {
  description = "세 번째 VM에 할당할 PCI 디바이스 (예: 0000:65:00.0)"
  type        = string
  default     = ""
}

# (백워드 호환) 간단한 count 기반 매핑 변수
variable "pci_mapping_1" {
  description = "첫 번째 VM에 할당할 Proxmox 리소스 매핑 ID (예: gpu0)"
  type        = string
  default     = ""
}

variable "pci_mapping_2" {
  description = "두 번째 VM에 할당할 Proxmox 리소스 매핑 ID (예: gpu1)"
  type        = string
  default     = ""
}

variable "pci_mapping_3" {
  description = "세 번째 VM에 할당할 Proxmox 리소스 매핑 ID (예: gpu2)"
  type        = string
  default     = ""
}

variable "hostpci_pcie" {
  description = "PCI 디바이스의 PCIe 모드 사용 여부"
  type        = bool
  default     = true
}

variable "hostpci_rombar" {
  description = "PCI 디바이스의 ROM BAR 사용 여부"
  type        = bool
  default     = false
}
