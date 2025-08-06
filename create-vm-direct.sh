#!/bin/bash
# Proxmox API를 직접 사용해서 VM 생성

PROXMOX_HOST="192.168.135.10:8006"
USERNAME="root@pam"
PASSWORD="cloud1234"
NODE="solutions"
TEMPLATE_ID="9000"
NEW_VM_ID="102"
VM_NAME="ubuntu-vm-terraform"

echo "Proxmox API를 통해 VM 생성 중..."

# VM 클론 생성
curl -k -d "newid=$NEW_VM_ID&name=$VM_NAME&full=1" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$TEMPLATE_ID/clone"

echo ""
echo "VM 설정 업데이트 중..."

# VM 설정 (메모리, CPU 등)
curl -k -d "memory=2048&cores=2" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/config"

echo ""
echo "Cloud-init 설정 중..."

# Cloud-init 설정
curl -k -d "ciuser=ubuntu&cipassword=ubuntu123&ipconfig0=ip=192.168.135.100/24,gw=192.168.135.1&nameserver=8.8.8.8" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/config"

echo ""
echo "VM 시작 중..."

# VM 시작
curl -k -d "" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/status/start"

echo ""
echo "VM 생성 및 시작이 완료되었습니다!"
echo "VM ID: $NEW_VM_ID"
echo "VM 이름: $VM_NAME"
echo "IP 주소: 192.168.135.100"