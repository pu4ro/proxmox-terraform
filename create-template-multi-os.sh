#!/bin/bash
# Ubuntu 템플릿 생성 스크립트 (22.04, 24.04 지원)
# 환경변수: 
#   OS_VERSION (22.04, 24.04)
#   PROXMOX_HOST (Proxmox 서버 IP)
#   PROXMOX_PASSWORD (Proxmox root 패스워드)

# 환경변수 설정 (기본값)
OS_VERSION=${OS_VERSION:-"22.04"}
PROXMOX_HOST=${PROXMOX_HOST:-"192.168.135.10"}
PROXMOX_PASSWORD=${PROXMOX_PASSWORD:-"cloud1234"}

# OS 버전별 설정
case "$OS_VERSION" in
    "22.04")
        VM_ID=9005
        VM_NAME="ubuntu-22-04-5-guest-agent"
        IMAGE_NAME="ubuntu-22.04.5-server-cloudimg-amd64.img"
        IMAGE_URL="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-server-cloudimg-amd64.img"
        ;;
    "24.04")
        VM_ID=9007
        VM_NAME="ubuntu-24-04-guest-agent"
        IMAGE_NAME="ubuntu-24.04-server-cloudimg-amd64.img"
        IMAGE_URL="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
        ;;
    *)
        echo "지원하지 않는 OS 버전: $OS_VERSION"
        echo "지원 버전: 22.04, 24.04"
        exit 1
        ;;
esac

STORAGE="local-lvm"

echo "=== Ubuntu $OS_VERSION Guest Agent 포함 템플릿 생성 ==="
echo "Proxmox Host: $PROXMOX_HOST"
echo "VM ID: $VM_ID"
echo "VM Name: $VM_NAME"
echo "Image: $IMAGE_NAME"
echo ""

# 기존 VM이 있으면 삭제
echo "기존 VM $VM_ID 확인 및 삭제..."
existing_vm=$(sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm list | grep -w $VM_ID" 2>/dev/null || echo "")

if [ ! -z "$existing_vm" ]; then
    echo "기존 VM $VM_ID 삭제 중..."
    sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
    "qm stop $VM_ID 2>/dev/null || true"
    sleep 5
    sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
    "qm destroy $VM_ID"
    echo "기존 VM 삭제 완료"
fi

# 이미지 다운로드 확인
echo "클라우드 이미지 확인 중..."
image_exists=$(sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"ls /var/lib/vz/template/iso/$IMAGE_NAME 2>/dev/null || echo 'not_found'")

if [ "$image_exists" = "not_found" ]; then
    echo "클라우드 이미지 다운로드 중..."
    sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
    "cd /var/lib/vz/template/iso && wget $IMAGE_URL"
    echo "이미지 다운로드 완료"
else
    echo "이미지가 이미 존재합니다: $IMAGE_NAME"
fi

# 1. VM 생성
echo "1. VM $VM_ID 생성 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm create $VM_ID --memory 2048 --cores 2 --name $VM_NAME --net0 virtio,bridge=vmbr0 --ostype l26"

# 2. 디스크 이미지 임포트
echo "2. 디스크 이미지 임포트 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"cd /var/lib/vz/template/iso && qm importdisk $VM_ID $IMAGE_NAME $STORAGE"

# 3. VM 기본 설정
echo "3. VM 기본 설정 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --ide2 $STORAGE:cloudinit"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --boot c --bootdisk scsi0"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --vga std"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --agent enabled=1"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --cpu host"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --machine q35"

# 4. 디스크 크기 조정 (300GB)
echo "4. 디스크 크기 조정 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm resize $VM_ID scsi0 +298G"

# 5. 네트워크 설정 (패키지 설치용 임시 설정)
echo "5. 네트워크 설정 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --ipconfig0 ip=192.168.135.200/23,gw=192.168.134.1"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --nameserver 8.8.8.8"

# 6. Guest Agent 설치용 cloud-config 생성
echo "6. Guest Agent 설치 스크립트 생성 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
'mkdir -p /var/lib/vz/snippets'

# OS 버전별 패키지 설치 방법 최적화
if [ "$OS_VERSION" = "24.04" ]; then
    # Ubuntu 24.04는 최신 패키지 관리 방식 사용
    GUEST_AGENT_CONFIG='#cloud-config
# Ubuntu 24.04 최적화 설정

package_update: true
package_upgrade: false
packages:
  - qemu-guest-agent

runcmd:
  - apt-get update
  - apt-get install -y qemu-guest-agent
  - systemctl daemon-reload
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - sleep 15
  - systemctl is-active qemu-guest-agent
  - echo "Guest Agent installation completed for Ubuntu 24.04" > /tmp/guest-agent-status
  - shutdown -h +1

final_message: "Ubuntu 24.04 Guest Agent installation completed successfully"'
else
    # Ubuntu 20.04, 22.04 공통 설정
    GUEST_AGENT_CONFIG='#cloud-config
# Ubuntu 20.04/22.04 호환 설정

package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent

runcmd:
  - apt-get update
  - apt-get install -y qemu-guest-agent
  - systemctl daemon-reload
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - sleep 15
  - systemctl is-active qemu-guest-agent
  - echo "Guest Agent installation completed" > /tmp/guest-agent-status
  - shutdown -h +1

final_message: "Guest Agent installation completed successfully"'
fi

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"cat > /var/lib/vz/snippets/install-guest-agent-$OS_VERSION.yml << 'EOF'
$GUEST_AGENT_CONFIG
EOF"

# 7. Cloud-init 사용자 데이터 적용
echo "7. Cloud-init 사용자 데이터 적용 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --cicustom user=local:snippets/install-guest-agent-$OS_VERSION.yml"

# 8. VM 시작 및 Guest Agent 설치
echo "8. VM 시작하여 Guest Agent 설치 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm start $VM_ID"

# 9. VM이 자동으로 종료될 때까지 대기
echo "9. Guest Agent 설치 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
    "qm status $VM_ID" 2>/dev/null | grep -o "stopped\|running" || echo "unknown")
    
    if [ "$status" = "stopped" ]; then
        echo "Guest Agent 설치 완료!"
        break
    fi
    
    echo "설치 진행 중... ($timeout초 남음)"
    sleep 15
    timeout=$((timeout-15))
done

if [ $timeout -le 0 ]; then
    echo "타임아웃 발생. 수동으로 VM 중지..."
    sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
    "qm stop $VM_ID"
    sleep 10
fi

# 10. 네트워크 설정 제거 (템플릿은 깨끗해야 함)
echo "10. 임시 네트워크 설정 제거 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --delete ipconfig0"

sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --delete nameserver"

# 11. 사용자 데이터 제거 (템플릿은 깨끗해야 함)
echo "11. 임시 사용자 데이터 제거 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm set $VM_ID --delete cicustom"

# 12. 템플릿으로 변환
echo "12. 템플릿으로 변환 중..."
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
"qm template $VM_ID"

echo ""
echo "=== Ubuntu $OS_VERSION Guest Agent 포함 템플릿 생성 완료! ==="
echo "Proxmox Host: $PROXMOX_HOST"
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "OS 버전: Ubuntu $OS_VERSION"
echo ""
echo "사용법:"
echo "  기본값: ./create-template-multi-os.sh"
echo "  커스텀: OS_VERSION=24.04 PROXMOX_HOST=192.168.1.100 PROXMOX_PASSWORD=mypass ./create-template-multi-os.sh"
echo ""
echo "환경변수:"
echo "  OS_VERSION: 22.04, 24.04 (기본: 22.04)"
echo "  PROXMOX_HOST: Proxmox 서버 IP (기본: 192.168.135.10)"
echo "  PROXMOX_PASSWORD: root 패스워드 (기본: cloud1234)"
echo ""
echo "이제 Terraform에서 template_id = $VM_ID 로 이 템플릿을 사용할 수 있습니다."