#!/bin/bash
# Proxmox API를 사용한 VM 생성 (최종 버전)

PROXMOX_HOST="192.168.135.10:8006"
USERNAME="root@pam"
PASSWORD="cloud1234"
NODE="solutions"
TEMPLATE_ID="9001"
NEW_VM_ID="150"
VM_NAME="ubuntu-vm-final"

echo "=== Proxmox VM 생성 스크립트 ==="
echo "템플릿: ubuntu-22-04-5-template (ID: $TEMPLATE_ID)"
echo "새 VM ID: $NEW_VM_ID"
echo "VM 이름: $VM_NAME"
echo ""

echo "1. 템플릿에서 VM 클론 생성 중..."
RESULT=$(curl -s -k -d "newid=$NEW_VM_ID&name=$VM_NAME&full=1" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$TEMPLATE_ID/clone")

echo "클론 결과: $RESULT"

sleep 5

echo "2. VM 구성 업데이트 중..."
curl -s -k -d "memory=2048&cores=2" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/config" > /dev/null

echo "3. Cloud-init 네트워크 설정 중..."
curl -s -k -d "ipconfig0=ip=192.168.135.101/24,gw=192.168.135.1&nameserver=8.8.8.8" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/config" > /dev/null

echo "4. VM 시작 중..."
curl -s -k -d "" \
  -u "$USERNAME:$PASSWORD" \
  "https://$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$NEW_VM_ID/status/start" > /dev/null

echo ""
echo "=== VM 생성 완료! ==="
echo "VM ID: $NEW_VM_ID"
echo "VM 이름: $VM_NAME"
echo "IP 주소: 192.168.135.101"
echo "사용자: ubuntu"
echo "비밀번호: ubuntu123"
echo ""
echo "VM이 부팅되는 데 1-2분 정도 소요됩니다."
echo "SSH 접속: ssh ubuntu@192.168.135.101"