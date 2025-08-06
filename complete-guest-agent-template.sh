#!/bin/bash
# SSH를 통해 Proxmox 서버에서 Guest Agent 템플릿 완성

VM_ID=9004

echo "=== VM 9004 Guest Agent 템플릿 완성 ==="

# 1. 디스크 크기 조정
echo "1. 디스크 크기 조정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm resize $VM_ID scsi0 +18G"

# 2. Cloud-init 기본 설정
echo "2. Cloud-init 기본 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ciuser ubuntu --cipassword cloud1234"

# 3. Guest Agent 설치용 cloud-config 생성
echo "3. Guest Agent 설치 스크립트 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"mkdir -p /var/lib/vz/snippets && cat > /var/lib/vz/snippets/install-guest-agent.yml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - echo \"Guest Agent installed and started\" > /tmp/guest-agent-status
power_state:
  mode: poweroff
  timeout: 300
EOF"

# 4. Cloud-init 사용자 데이터 적용
echo "4. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom \"user=local:snippets/install-guest-agent.yml\""

# 5. VM 시작 및 Guest Agent 설치
echo "5. VM 시작하여 Guest Agent 설치 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 6. VM이 자동으로 종료될 때까지 대기
echo "6. Guest Agent 설치 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm status $VM_ID" | grep -o "stopped\|running")
    
    if [ "$status" = "stopped" ]; then
        echo "Guest Agent 설치 완료!"
        break
    fi
    
    echo "설치 진행 중... ($timeout초 남음)"
    sleep 10
    timeout=$((timeout-10))
done

if [ $timeout -le 0 ]; then
    echo "타임아웃 발생. 수동으로 VM 중지..."
    sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm stop $VM_ID"
    sleep 10
fi

# 7. 템플릿으로 변환
echo "7. 템플릿으로 변환 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm template $VM_ID"

echo ""
echo "=== Guest Agent 포함 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: ubuntu-22-04-5-guest-agent"