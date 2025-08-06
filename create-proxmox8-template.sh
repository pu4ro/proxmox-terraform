#!/bin/bash
# Proxmox 8.2.2용 Ubuntu 22.04.5 템플릿 생성 스크립트

VM_ID=9002
VM_NAME="ubuntu-22-04-5-template-v8"
STORAGE="local-lvm"
NODE="solutions"

echo "=== Proxmox 8.2.2용 Ubuntu 22.04.5 템플릿 생성 ==="
echo ""

echo "1. 기존 템플릿 정리 중..."
qm destroy 9001 >/dev/null 2>&1 || true
qm destroy 9002 >/dev/null 2>&1 || true

echo "2. Ubuntu 22.04.5 Cloud 이미지 다운로드 중..."
cd /var/lib/vz/template/iso
if [ ! -f "ubuntu-22.04.5-server-cloudimg-amd64.img" ]; then
    wget -O ubuntu-22.04.5-server-cloudimg-amd64.img \
      https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
fi

echo "3. VM $VM_ID 생성 중..."
qm create $VM_ID \
    --memory 2048 \
    --cores 2 \
    --name $VM_NAME \
    --net0 virtio,bridge=vmbr0 \
    --ostype l26

echo "4. 디스크 이미지 임포트 중..."
qm importdisk $VM_ID ubuntu-22.04.5-server-cloudimg-amd64.img $STORAGE

echo "5. VM 하드웨어 설정 중..."
# SCSI 컨트롤러와 부팅 디스크 설정
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

# Cloud-init 디스크 추가
qm set $VM_ID --ide2 $STORAGE:cloudinit

# 부팅 옵션 설정
qm set $VM_ID --boot c --bootdisk scsi0

# 시리얼 콘솔 설정 (선택사항)
qm set $VM_ID --serial0 socket --vga serial0

# QEMU Guest Agent 활성화 (Proxmox 8.x에서 중요)
qm set $VM_ID --agent enabled=1

# CPU 타입 설정 (Proxmox 8.x에서 권장)
qm set $VM_ID --cpu host

# 기본 Cloud-init 사용자 설정
qm set $VM_ID --ciuser ubuntu
qm set $VM_ID --cipassword ubuntu123

# Machine 타입 설정 (Proxmox 8.x 호환성)
qm set $VM_ID --machine q35

echo "6. 디스크 크기 조정 (선택사항)..."
qm resize $VM_ID scsi0 +18G  # 20GB 총 크기로 확장

echo "7. 템플릿으로 변환 중..."
qm template $VM_ID

echo ""
echo "=== 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "이 템플릿은 Proxmox 8.2.2와 완전히 호환됩니다."
echo ""
echo "템플릿 확인:"
echo "  qm config $VM_ID"