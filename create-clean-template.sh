#!/bin/bash
# Serial 없는 깔끔한 템플릿 생성

VM_ID=9003
VM_NAME="ubuntu-22-04-5-clean"
STORAGE="local-lvm"

echo "=== 깔끔한 Ubuntu 22.04.5 템플릿 생성 ==="

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

echo "3. VM 설정 중..."
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

# 기본 Cloud-init 사용자 설정
qm set $VM_ID --ciuser ubuntu
qm set $VM_ID --cipassword cloud1234

# Machine 타입 설정
qm set $VM_ID --machine q35

echo "4. 디스크 크기 조정..."
qm resize $VM_ID scsi0 +18G

echo "5. 템플릿으로 변환..."
qm template $VM_ID

echo ""
echo "=== 깔끔한 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"