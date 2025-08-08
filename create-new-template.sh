#!/bin/bash
# 새로운 PC 환경에서 동일한 Guest Agent 포함 템플릿 생성

VM_ID=9005
VM_NAME="ubuntu-22-04-5-guest-agent-new"
STORAGE="local-lvm"

echo "=== 새로운 Guest Agent 포함 템플릿 생성 ==="

# 1. VM 생성
echo "1. VM $VM_ID 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm create $VM_ID --memory 2048 --cores 2 --name $VM_NAME --net0 virtio,bridge=vmbr0 --ostype l26"

# 2. 디스크 이미지 임포트
echo "2. 디스크 이미지 임포트 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"cd /var/lib/vz/template/iso && qm importdisk $VM_ID ubuntu-22.04.5-server-cloudimg-amd64.img $STORAGE"

# 3. VM 기본 설정
echo "3. VM 기본 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ide2 $STORAGE:cloudinit"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --boot c --bootdisk scsi0"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --vga std"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --agent enabled=1"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cpu host"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --machine q35"

# 4. 디스크 크기 조정 (300GB)
echo "4. 디스크 크기 조정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm resize $VM_ID scsi0 +298G"

# 5. 네트워크 설정 (패키지 설치용 임시 설정)
echo "5. 네트워크 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ipconfig0 ip=192.168.135.200/23,gw=192.168.134.1"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --nameserver 8.8.8.8"

# 6. Guest Agent 설치용 cloud-config 생성 (Cloud-init 25.1.4 기준)
echo "6. Guest Agent 설치 스크립트 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'mkdir -p /var/lib/vz/snippets'

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'cat > /var/lib/vz/snippets/install-guest-agent-new.yml << "EOF"
#cloud-config
# 모든 cloud-init 버전 호환 설정

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

final_message: "Guest Agent installation completed successfully"
EOF'

# 7. Cloud-init 사용자 데이터 적용
echo "7. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom user=local:snippets/install-guest-agent-new.yml"

# 8. VM 시작 및 Guest Agent 설치
echo "8. VM 시작하여 Guest Agent 설치 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 9. VM이 자동으로 종료될 때까지 대기
echo "9. Guest Agent 설치 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
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
    sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm stop $VM_ID"
    sleep 10
fi

# 10. 네트워크 설정 제거 (템플릿은 깨끗해야 함)
echo "10. 임시 네트워크 설정 제거 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --delete ipconfig0"

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --delete nameserver"

# 11. 템플릿으로 변환
echo "11. 템플릿으로 변환 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm template $VM_ID"

echo ""
echo "=== 새로운 Guest Agent 포함 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo ""
echo "이제 Terraform에서 이 템플릿을 사용할 수 있습니다."