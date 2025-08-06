#!/bin/bash
# Ubuntu 22.04.5 Terraform용 올바른 템플릿 생성 스크립트

VM_ID=9001
VM_NAME="ubuntu-22-04-5-template"
STORAGE="local-lvm"
NODE="solutions"

echo "기존 템플릿 정리 중..."
qm destroy 9000 >/dev/null 2>&1 || true

echo "Ubuntu 22.04.5 Cloud 이미지 다운로드 중..."
cd /var/lib/vz/template/iso
wget -O ubuntu-22.04.5-server-cloudimg-amd64.img \
  https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

echo "VM $VM_ID 생성 중..."
qm create $VM_ID --memory 2048 --cores 2 --name $VM_NAME --net0 virtio,bridge=vmbr0

echo "디스크 이미지 임포트 중..."
qm importdisk $VM_ID ubuntu-22.04.5-server-cloudimg-amd64.img $STORAGE

echo "VM 설정 적용 중..."
# 디스크 연결
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

# Cloud-init 디스크 추가
qm set $VM_ID --ide2 $STORAGE:cloudinit

# 부팅 설정
qm set $VM_ID --boot c --bootdisk scsi0

# 시리얼 콘솔 설정 (cloud-init 로그 확인용)
qm set $VM_ID --serial0 socket --vga serial0

# Cloud-init 기본 설정
qm set $VM_ID --ciuser ubuntu
qm set $VM_ID --cipassword ubuntu123
qm set $VM_ID --sshkey ~/.ssh/id_rsa.pub >/dev/null 2>&1 || true

# Agent 활성화
qm set $VM_ID --agent enabled=1

echo "템플릿으로 변환 중..."
qm template $VM_ID

echo "Ubuntu 22.04.5 템플릿이 성공적으로 생성되었습니다!"
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"