#!/bin/bash
# 패스워드 인증만 사용하는 템플릿 생성 (공개키 인증 비활성화)

VM_ID=9009
VM_NAME="ubuntu-22-04-5-password-only"
STORAGE="local-lvm"

echo "=== 패스워드 인증만 사용하는 300GB 템플릿 생성 ==="

# 기존 VM 9009 삭제 (있다면)
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm destroy $VM_ID --purge 2>/dev/null || echo 'VM $VM_ID 없음 또는 이미 삭제됨'"

# 1. VM 생성 - 고사양으로 생성
echo "1. VM $VM_ID 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm create $VM_ID --memory 32768 --cores 16 --name $VM_NAME --net0 virtio,bridge=vmbr0 --ostype l26"

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

# 4. 디스크 크기를 300GB로 조정
echo "4. 디스크 크기를 300GB로 조정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm resize $VM_ID scsi0 +298G"

# 5. Cloud-init 기본 설정
echo "5. Cloud-init 기본 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ciuser ubuntu --cipassword cloud1234"

# 6. 패스워드 인증만 사용하는 cloud-config 생성
echo "6. 패스워드 인증 전용 설정 스크립트 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'mkdir -p /var/lib/vz/snippets'

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'cat > /var/lib/vz/snippets/password-only-setup.yml << "EOF"
#cloud-config

# 필요한 패키지 설치
package_update: true
package_upgrade: false
packages:
  - qemu-guest-agent
  - openssh-server
  - cloud-guest-utils
  - growpart

# 디스크 자동 확장
growpart:
  mode: auto
  devices: ["/"]
resize_rootfs: true

# SSH 설정을 패스워드 인증만 허용하도록 설정
runcmd:
  # Guest Agent 먼저 시작
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  
  # SSH 설정 파일 직접 수정 - 패스워드 인증만 허용
  - sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
  - sed -i "s/^PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
  - sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication no/" /etc/ssh/sshd_config  
  - sed -i "s/^PubkeyAuthentication.*/PubkeyAuthentication no/" /etc/ssh/sshd_config
  - sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
  - sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
  - echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  - echo "PubkeyAuthentication no" >> /etc/ssh/sshd_config
  
  # SSH 서비스 재시작
  - systemctl restart ssh
  - systemctl enable ssh
  
  # ubuntu 사용자 패스워드 확실히 설정
  - echo "ubuntu:cloud1234" | chpasswd
  
  # 디스크 확장
  - growpart /dev/sda 1 || true
  - resize2fs /dev/sda1 || true
  
  # 상태 파일 생성
  - echo "SSH: PASSWORD ONLY (PubkeyAuthentication=no)" > /tmp/ssh-status
  - echo "ubuntu user password: cloud1234" >> /tmp/ssh-status
  - sshd -T | grep -E "(passwordauth|pubkeyauth)" > /tmp/sshd-config-check
  - echo "Guest Agent: RUNNING" > /tmp/guest-agent-status
  - df -h > /tmp/disk-status

# 부팅 시 디스크 확장 체크
bootcmd:
  - cloud-init-per once growpart-check growpart /dev/sda 1 || true
  - cloud-init-per once resize2fs-check resize2fs /dev/sda1 || true

power_state:
  mode: poweroff
  timeout: 300
EOF'

# 7. Cloud-init 사용자 데이터 적용
echo "7. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom user=local:snippets/password-only-setup.yml"

# 8. VM 시작 및 설정 적용
echo "8. VM 시작하여 패스워드 전용 SSH 설정 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 9. VM이 자동으로 종료될 때까지 대기
echo "9. 패스워드 전용 SSH 설정 적용 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm status $VM_ID" 2>/dev/null | grep -o "stopped\|running" || echo "unknown")
    
    if [ "$status" = "stopped" ]; then
        echo "패스워드 전용 SSH 설정 적용 완료!"
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
echo "=== 패스워드 전용 SSH 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo ""
echo "SSH 인증 설정:"
echo "  - PasswordAuthentication yes"
echo "  - PubkeyAuthentication no (공개키 인증 비활성화)"
echo "  - ubuntu 사용자 패스워드: cloud1234"
echo "  - SSH 접속: ssh ubuntu@[IP주소]"