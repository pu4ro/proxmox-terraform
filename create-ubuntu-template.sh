#!/bin/bash
# Ubuntu 22.04.5 템플릿 생성 스크립트
# Proxmox 서버에서 직접 실행

VM_ID=9000
VM_NAME="ubuntu-22.04.5"
STORAGE="local-lvm"

echo "Ubuntu 22.04 Cloud 이미지 다운로드 중..."
cd /var/lib/vz/template/iso
wget -O ubuntu-22.04-server-cloudimg-amd64.img \
  https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img

echo "VM $VM_ID 생성 중..."
qm create $VM_ID --memory 2048 --cores 2 --name $VM_NAME --net0 virtio,bridge=vmbr0

echo "디스크 이미지 임포트 중..."
qm importdisk $VM_ID ubuntu-22.04-server-cloudimg-amd64.img $STORAGE

echo "VM 설정 중..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 $STORAGE:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0

echo "템플릿으로 변환 중..."
qm template $VM_ID

echo "Ubuntu 22.04.5 템플릿이 성공적으로 생성되었습니다!"
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"