#!/bin/bash
# QEMU Guest Agent가 포함된 Ubuntu 22.04.5 템플릿 생성

VM_ID=9004
VM_NAME="ubuntu-22-04-5-with-agent"
STORAGE="local-lvm"
ISO_PATH="/var/lib/vz/template/iso/ubuntu-22.04.5-server-cloudimg-amd64.img"

echo "=== QEMU Guest Agent 포함 Ubuntu 22.04.5 템플릿 생성 ==="

echo "1. VM $VM_ID 생성 중..."
qm create $VM_ID \
    --memory 2048 \
    --cores 2 \
    --name $VM_NAME \
    --net0 virtio,bridge=vmbr0 \
    --ostype l26

echo "2. 디스크 이미지 임포트 중..."
cd /var/lib/vz/template/iso
qm importdisk $VM_ID ubuntu-22.04.5-server-cloudimg-amd64.img $STORAGE

echo "3. VM 기본 설정 중..."
# SCSI 컨트롤러와 부팅 디스크 설정
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

# Cloud-init 디스크 추가
qm set $VM_ID --ide2 $STORAGE:cloudinit

# 부팅 옵션 설정
qm set $VM_ID --boot c --bootdisk scsi0

# VGA 표준으로 설정 (serial 사용 안함)
qm set $VM_ID --vga std

# QEMU Guest Agent 활성화
qm set $VM_ID --agent enabled=1

# CPU 타입 설정
qm set $VM_ID --cpu host

# Machine 타입 설정
qm set $VM_ID --machine q35

echo "4. 디스크 크기 조정..."
qm resize $VM_ID scsi0 +18G

echo "5. Cloud-init 설정으로 Guest Agent 설치 준비..."
# Cloud-init 사용자 데이터로 Guest Agent 설치
cat > /tmp/user-data-$VM_ID << 'EOF'
#cloud-config
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
power_state:
  mode: poweroff
  timeout: 300
EOF

# Cloud-init 설정 적용
qm set $VM_ID --cicustom "user=local:snippets/user-data-$VM_ID"

echo "6. User data를 snippets 디렉토리에 복사..."
cp /tmp/user-data-$VM_ID /var/lib/vz/snippets/user-data-$VM_ID

echo "7. VM 시작하여 Guest Agent 설치..."
qm start $VM_ID

echo "8. VM이 종료될 때까지 대기 (Guest Agent 설치 완료 후 자동 종료)..."
while qm status $VM_ID | grep -q "running"; do
    echo "VM 설치 진행 중... (60초 후 다시 확인)"
    sleep 60
done

echo "9. Guest Agent 설치 완료, 템플릿으로 변환..."
qm template $VM_ID

echo "10. 임시 파일 정리..."
rm -f /tmp/user-data-$VM_ID

echo ""
echo "=== QEMU Guest Agent 포함 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "Guest Agent가 설치되어 Terraform에서 정상적으로 VM 생성이 가능합니다."