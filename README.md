# Proxmox Terraform Configuration

이 Terraform 구성은 Proxmox VE에서 VM과 템플릿을 생성하고 관리하기 위한 모듈식 접근 방식을 제공합니다.

## 기능

- **VM 생성**: 기존 템플릿에서 VM 생성
- **템플릿 생성**: ISO 파일에서 새 템플릿 생성
- **Cloud-Init 지원**: IP 설정, 사용자 계정, SSH 키 자동 구성
- **모듈식 구조**: 재사용 가능한 VM 및 템플릿 모듈

## 구조

```
.
├── main.tf                    # 메인 Terraform 구성
├── variables.tf               # 전역 변수
├── terraform.tfvars.example   # 환경 변수 예제
├── examples.tf                # 사용 예제
├── modules/
│   ├── vm/                    # VM 생성 모듈
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── template/              # 템플릿 생성 모듈
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

## 사전 요구사항

1. Terraform >= 1.0
2. Proxmox VE 서버
3. Proxmox API 액세스 권한

## 설정

1. **terraform.tfvars 파일 생성**:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. **terraform.tfvars 편집**:
```hcl
proxmox_api_url      = "https://your-proxmox-server:8006/api2/json"
proxmox_user         = "root@pam"
proxmox_password     = "your-password"
proxmox_tls_insecure = true
```

## 사용법

### 1. 초기화
```bash
terraform init
```

### 2. 계획 확인
```bash
terraform plan
```

### 3. 적용
```bash
terraform apply
```

## 예제

### 템플릿 생성
```hcl
module "ubuntu_template" {
  source = "./modules/template"
  
  template_name = "ubuntu-22.04-template"
  target_node   = "proxmox-node1"
  template_id   = 9000
  iso_file      = "local:iso/ubuntu-22.04-server-amd64.iso"
}
```

### VM 생성
```hcl
module "web_server" {
  source = "./modules/vm"
  
  vm_name       = "web-server-01"
  target_node   = "proxmox-node1"
  template_name = "ubuntu-22.04-template"
  
  ip_address = "192.168.1.100"
  gateway    = "192.168.1.1"
  
  cloud_init_user     = "ubuntu"
  cloud_init_password = "secure-password"
  ssh_public_keys     = file("~/.ssh/id_rsa.pub")
}
```

## 주요 변수

### VM 모듈
- `vm_name`: VM 이름
- `template_name`: 사용할 템플릿 이름
- `ip_address`: 고정 IP 주소
- `gateway`: 게이트웨이 IP
- `cloud_init_user`: Cloud-init 사용자명
- `ssh_public_keys`: SSH 공개 키

### 템플릿 모듈
- `template_name`: 템플릿 이름
- `iso_file`: ISO 파일 경로
- `template_id`: 템플릿 VM ID

## 정리
```bash
terraform destroy
```