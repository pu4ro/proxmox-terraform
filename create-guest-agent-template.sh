#!/bin/bash
# Proxmox 서버에서 실행할 Guest Agent 포함 템플릿 생성 스크립트

VM_ID=9004
VM_NAME="ubuntu-22-04-5-guest-agent"
STORAGE="local-lvm"

echo "=== Proxmox 서버에서 실행할 Guest Agent 템플릿 생성 가이드 ==="
echo ""
echo "이 스크립트를 Proxmox 서버(192.168.135.10)에서 root 권한으로 실행하세요:"
echo ""
echo "ssh root@192.168.135.10"
echo "패스워드: cloud1234"
echo ""
echo "그 다음 아래 명령들을 순서대로 실행:"
echo ""

cat << 'EOF'
# 1. VM 생성
VM_ID=9004
VM_NAME="ubuntu-22-04-5-guest-agent"
STORAGE="local-lvm"

qm create $VM_ID \
    --memory 2048 \
    --cores 2 \
    --name $VM_NAME \
    --net0 virtio,bridge=vmbr0 \
    --ostype l26

# 2. 디스크 이미지 임포트
cd /var/lib/vz/template/iso
qm importdisk $VM_ID ubuntu-22.04.5-server-cloudimg-amd64.img $STORAGE

# 3. VM 설정
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 $STORAGE:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --vga std
qm set $VM_ID --agent enabled=1
qm set $VM_ID --cpu host
qm set $VM_ID --machine q35

# 4. 디스크 크기 조정
qm resize $VM_ID scsi0 +18G

# 5. Cloud-init으로 Guest Agent 설치 설정
qm set $VM_ID --ciuser ubuntu
qm set $VM_ID --cipassword cloud1234

# 6. Guest Agent 설치를 위한 사용자 스크립트 생성
mkdir -p /var/lib/vz/snippets

cat > /var/lib/vz/snippets/install-guest-agent.yml << 'USERDATA'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - echo "Guest Agent installed and started" > /tmp/guest-agent-status
power_state:
  mode: poweroff
  timeout: 300
USERDATA

# 7. Cloud-init 사용자 데이터 적용
qm set $VM_ID --cicustom "user=local:snippets/install-guest-agent.yml"

# 8. VM 시작 및 Guest Agent 설치
echo "VM을 시작하여 Guest Agent를 설치합니다..."
qm start $VM_ID

# 9. VM이 자동으로 종료될 때까지 대기
echo "Guest Agent 설치 중... (최대 5분 소요)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(qm status $VM_ID | grep -o "stopped\|running")
    if [ "$status" = "stopped" ]; then
        echo "Guest Agent 설치 완료!"
        break
    fi
    echo "설치 진행 중... ($timeout초 남음)"
    sleep 10
    timeout=$((timeout-10))
done

# 10. 템플릿으로 변환
echo "템플릿으로 변환 중..."
qm template $VM_ID

echo ""
echo "=== Guest Agent 포함 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
EOF

echo ""
echo "위 명령들을 Proxmox 서버에서 실행한 후, Terraform으로 VM을 생성할 수 있습니다."