#!/bin/bash
# SSH 패스워드 인증이 가능한 Guest Agent 포함 템플릿 생성

VM_ID=9005
VM_NAME="ubuntu-22-04-5-ssh-enabled"
STORAGE="local-lvm"

echo "=== SSH 패스워드 인증 가능한 템플릿 생성 ==="

# 기존 VM 9005 삭제 (있다면)
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm destroy $VM_ID --purge 2>/dev/null || echo 'VM $VM_ID 없음 또는 이미 삭제됨'"

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

# 4. 디스크 크기 조정
echo "4. 디스크 크기 조정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm resize $VM_ID scsi0 +18G"

# 5. Cloud-init 기본 설정
echo "5. Cloud-init 기본 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ciuser ubuntu --cipassword cloud1234"

# 6. SSH 패스워드 인증이 가능한 Guest Agent 설치용 cloud-config 생성
echo "6. SSH 활성화 및 Guest Agent 설치 스크립트 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'mkdir -p /var/lib/vz/snippets'

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'cat > /var/lib/vz/snippets/install-guest-agent-ssh.yml << "EOF"
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - openssh-server

# SSH 설정 수정
write_files:
  - path: /etc/ssh/sshd_config.d/50-cloud-init.conf
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      PermitRootLogin no
      ChallengeResponseAuthentication no
      UsePAM yes
    permissions: "0644"

runcmd:
  # Guest Agent 설정
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  # SSH 서비스 재시작
  - systemctl restart ssh
  - systemctl enable ssh
  # 상태 확인 파일 생성
  - echo "Guest Agent installed and started" > /tmp/guest-agent-status
  - echo "SSH password authentication enabled" > /tmp/ssh-status

power_state:
  mode: poweroff
  timeout: 300
EOF'

# 7. Cloud-init 사용자 데이터 적용
echo "7. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom user=local:snippets/install-guest-agent-ssh.yml"

# 8. VM 시작 및 설정 적용
echo "8. VM 시작하여 SSH 및 Guest Agent 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 9. VM이 자동으로 종료될 때까지 대기
echo "9. 설정 적용 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm status $VM_ID" 2>/dev/null | grep -o "stopped\|running" || echo "unknown")
    
    if [ "$status" = "stopped" ]; then
        echo "설정 적용 완료!"
        break
    fi
    
    echo "설정 적용 중... ($timeout초 남음)"
    sleep 15
    timeout=$((timeout-15))
done

if [ $timeout -le 0 ]; then
    echo "타임아웃 발생. 수동으로 VM 중지..."
    sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm stop $VM_ID"
    sleep 10
fi

# 10. 템플릿으로 변환
echo "10. 템플릿으로 변환 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm template $VM_ID"

echo ""
echo "=== SSH 패스워드 인증 가능한 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "SSH 접속: ssh ubuntu@[IP주소] (패스워드: cloud1234)"