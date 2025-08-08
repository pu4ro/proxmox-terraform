# Proxmox Terraform Configuration

이 Terraform 구성은 Proxmox VE에서 VM을 자동으로 생성하고 관리하기 위한 완전 자동화된 솔루션을 제공합니다.

## 🚀 주요 기능

- **멀티 VM 배포**: 동일한 스펙으로 여러 VM 동시 생성
- **IP 자동 할당**: ping 테스트를 통한 사용 가능한 IP 자동 탐지 및 할당
- **추가 디스크 지원**: 선택적 추가 디스크 구성 가능
- **Guest Agent 지원**: QEMU Guest Agent 사전 설치된 템플릿 사용
- **Cloud-Init 호환**: 모든 Cloud-Init 버전 호환 설계
- **SSH 즉시 접속**: 배포 완료 즉시 SSH 접속 가능

## 📋 사전 요구사항

1. **Terraform** >= 1.0
2. **Proxmox VE** 서버
3. **Ubuntu 22.04.5 Cloud Image** (`ubuntu-22.04.5-server-cloudimg-amd64.img`)
4. **SSH 키 페어** (자동 생성됨)

## 📁 프로젝트 구조

```
proxmox-terraform/
├── main.tf                    # 메인 Terraform 구성
├── variables.tf              # 변수 정의
├── terraform.tfvars         # 환경 설정
├── find-available-ip.sh     # IP 자동 탐지 스크립트
├── create-new-template.sh   # 템플릿 생성 스크립트
└── modules/                 # 재사용 가능한 모듈들
    ├── vm/
    └── template/
```

## ⚙️ 설정

### 1. 템플릿 생성

먼저 Guest Agent가 포함된 Ubuntu 템플릿을 생성합니다:

```bash
# 템플릿 생성 스크립트 실행
./create-new-template.sh
```

이 스크립트는 다음을 수행합니다:
- Ubuntu 22.04.5 Cloud Image 기반 템플릿 생성 (ID: 9005)
- QEMU Guest Agent 자동 설치 및 활성화
- 300GB 기본 디스크 할당
- Cloud-Init 25.1.4 호환 설정

### 2. Terraform 변수 설정

`terraform.tfvars` 파일을 편집합니다:

```hcl
# Proxmox 연결 설정
proxmox_api_url      = "https://192.168.135.10:8006/api2/json"
proxmox_user         = "root@pam"
proxmox_password     = "your-password"
proxmox_tls_insecure = true

# VM 사양 설정
vm_memory    = 32768  # 32GB RAM
vm_cores     = 16     # 16 CPU 코어

# 멀티 VM 설정
vm_count = 3                     # 생성할 VM 개수
vm_name_prefix = "ubuntu-server" # VM 이름 접두사

# 추가 디스크 설정 (선택사항)
additional_disk_enabled = true
additional_disk_size    = 200    # 200GB 추가 디스크
additional_disk_storage = "local-lvm"
```

## 🎯 사용법

### 1. 초기화 및 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 배포 실행
terraform apply -auto-approve
```

### 2. 배포 결과

배포가 완료되면 다음과 같은 출력을 볼 수 있습니다:

```
ssh_commands = [
  "ssh ubuntu@192.168.135.30  # ubuntu-server-1",
  "ssh ubuntu@192.168.135.32  # ubuntu-server-2",
  "ssh ubuntu@192.168.135.33  # ubuntu-server-3",
]

vm_details = {
  "ubuntu-server-1" = {
    "ip" = "192.168.135.30"
    "ssh_command" = "ssh ubuntu@192.168.135.30"
    "vm_id" = 106
  }
  # ... 추가 VM 정보
}
```

### 3. SSH 접속

```bash
# 패스워드 로그인 (기본: ubuntu/cloud1234)
ssh ubuntu@192.168.135.30

# 또는 SSH 키 로그인 (자동 설정됨)
ssh ubuntu@192.168.135.30
```

## 🔧 주요 변수

### 필수 변수
- `proxmox_api_url`: Proxmox API URL
- `proxmox_user`: Proxmox 사용자명
- `proxmox_password`: Proxmox 비밀번호

### VM 설정
- `vm_count`: 생성할 VM 개수 (기본: 1)
- `vm_name_prefix`: VM 이름 접두사 (기본: "ubuntu-vm")
- `vm_memory`: 메모리 크기 MB (기본: 16384)
- `vm_cores`: CPU 코어 수 (기본: 16)

### 추가 디스크 설정
- `additional_disk_enabled`: 추가 디스크 활성화 (기본: false)
- `additional_disk_size`: 추가 디스크 크기 GB (기본: 100)
- `additional_disk_storage`: 추가 디스크 스토리지 (기본: "local-lvm")

## 🌐 네트워크 설정

시스템은 `192.168.135.30`~`192.168.135.100` 범위에서 자동으로 사용 가능한 IP를 찾아 할당합니다:

- **IP 범위**: 192.168.135.30 - 192.168.135.100
- **서브넷**: /23 (192.168.134.0/23)
- **게이트웨이**: 192.168.134.1
- **DNS**: 8.8.8.8, 1.1.1.1

## 📖 사용 예제

### 단일 VM 배포
```bash
# terraform.tfvars에서 설정
vm_count = 1
vm_name_prefix = "web-server"
additional_disk_enabled = false
```

### 개발 환경 (3대 VM)
```bash
vm_count = 3
vm_name_prefix = "dev-server"
vm_memory = 16384
vm_cores = 8
additional_disk_enabled = true
additional_disk_size = 100
```

### 프로덕션 환경 (5대 VM)
```bash
vm_count = 5
vm_name_prefix = "prod-server"
vm_memory = 32768
vm_cores = 16
additional_disk_enabled = true
additional_disk_size = 500
```

## 🛠️ 고급 사용법

### 1. VM 개수 변경
```bash
# terraform.tfvars에서 vm_count 변경 후
terraform apply
```

### 2. 추가 디스크 활성화
```bash
# terraform.tfvars에서 설정
additional_disk_enabled = true
additional_disk_size = 200

terraform apply
```

### 3. VM 스케일링
```bash
# 현재 3대 → 5대로 확장
vm_count = 5
terraform apply

# 5대 → 2대로 축소
vm_count = 2
terraform apply
```

## 🔍 트러블슈팅

### 1. IP 충돌 문제
- `find-available-ip.sh`가 자동으로 사용 가능한 IP를 탐지합니다
- 필요시 IP 범위를 수정하여 사용하세요

### 2. SSH 접속 불가
- 템플릿에서 `cicustom` 설정이 제거되었는지 확인
- Cloud-Init이 정상적으로 사용자 계정을 생성했는지 확인

### 3. 템플릿 문제
- 템플릿 ID 9005가 존재하는지 확인
- Guest Agent가 정상 설치되었는지 확인

## 🧹 정리

```bash
# 모든 VM 삭제
terraform destroy -auto-approve

# 템플릿도 함께 정리 (수동)
# Proxmox 웹 인터페이스에서 템플릿 ID 9005 삭제
```

---

🎉 **완전 자동화된 Proxmox VM 관리 솔루션을 즐겨보세요!**