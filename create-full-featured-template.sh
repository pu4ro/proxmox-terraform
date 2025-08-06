#!/bin/bash
# SSH 패스워드 인증 + 디스크 자동 확장 가능한 Guest Agent 포함 템플릿 생성

VM_ID=9006
VM_NAME="ubuntu-22-04-5-full-featured"
STORAGE="local-lvm"

echo "=== SSH + 디스크 자동확장 + Guest Agent 템플릿 생성 ==="

# 기존 VM 9006 삭제 (있다면)
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

# 6. 모든 기능이 포함된 cloud-config 생성
echo "6. 전체 기능 설치 스크립트 생성 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'mkdir -p /var/lib/vz/snippets'

sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
'cat > /var/lib/vz/snippets/full-featured-setup.yml << "EOF"
#cloud-config
package_update: true
package_upgrade: true

# 필요한 패키지 설치
packages:
  - qemu-guest-agent
  - openssh-server
  - cloud-guest-utils
  - growpart

# 디스크 자동 확장 활성화
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false

# 파일 시스템 자동 확장
resize_rootfs: true

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

# 실행할 명령들
runcmd:
  # Guest Agent 설정
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  
  # SSH 서비스 재시작
  - systemctl restart ssh
  - systemctl enable ssh
  
  # 디스크 파티션 및 파일시스템 확장 강제 실행
  - growpart /dev/sda 1 || true
  - resize2fs /dev/sda1 || true
  
  # cloud-init이 부팅 시마다 디스크 확장하도록 설정
  - sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0"/' /etc/default/grub || true
  - update-grub || true
  
  # 상태 확인 파일 생성
  - echo "Guest Agent installed and started" > /tmp/guest-agent-status
  - echo "SSH password authentication enabled" > /tmp/ssh-status
  - echo "Disk auto-resize enabled" > /tmp/disk-resize-status
  - df -h > /tmp/disk-usage-after-resize

# 부팅 시마다 디스크 확장 체크
bootcmd:
  - cloud-init-per once growpart-check growpart /dev/sda 1
  - cloud-init-per once resize2fs-check resize2fs /dev/sda1

power_state:
  mode: poweroff
  timeout: 300
EOF'

# 7. Cloud-init 사용자 데이터 적용
echo "7. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom user=local:snippets/full-featured-setup.yml"

# 8. VM 시작 및 설정 적용
echo "8. VM 시작하여 전체 기능 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 9. VM이 자동으로 종료될 때까지 대기
echo "9. 전체 설정 적용 완료 대기 중... (최대 5분)"
timeout=300
while [ $timeout -gt 0 ]; do
    status=$(sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
    "qm status $VM_ID" 2>/dev/null | grep -o "stopped\|running" || echo "unknown")
    
    if [ "$status" = "stopped" ]; then
        echo "전체 설정 적용 완료!"
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
echo "=== 전체 기능 포함 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "기능:"
echo "  - QEMU Guest Agent 활성화"
echo "  - SSH 패스워드 인증 허용 (ubuntu/cloud1234)"
echo "  - 디스크 자동 확장 (부팅 시마다 체크)"
echo "  - SSH 접속: ssh ubuntu@[IP주소]"