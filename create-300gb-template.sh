#!/bin/bash
# 300GB 디스크 크기를 가진 고사양 템플릿 생성

VM_ID=9007
VM_NAME="ubuntu-22-04-5-300gb"
STORAGE="local-lvm"

echo "=== 300GB 고사양 템플릿 생성 ==="

# 기존 VM 9007 삭제 (있다면)
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

# 4. 디스크 크기를 300GB로 크게 조정
echo "4. 디스크 크기를 300GB로 조정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm resize $VM_ID scsi0 +298G"  # 원본 2GB + 298GB = 300GB

# 5. Cloud-init 기본 설정
echo "5. Cloud-init 기본 설정 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --ciuser ubuntu --cipassword cloud1234"

# 6. Cloud-init 사용자 데이터 적용 (기존 스크립트 재사용)
echo "6. Cloud-init 사용자 데이터 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm set $VM_ID --cicustom user=local:snippets/full-featured-setup.yml"

# 7. VM 시작 및 설정 적용
echo "7. VM 시작하여 전체 설정 적용 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm start $VM_ID"

# 8. VM이 자동으로 종료될 때까지 대기
echo "8. 설정 적용 완료 대기 중... (최대 5분)"
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

# 9. 템플릿으로 변환
echo "9. 템플릿으로 변환 중..."
sshpass -p 'cloud1234' ssh -o StrictHostKeyChecking=no root@192.168.135.10 \
"qm template $VM_ID"

echo ""
echo "=== 300GB 고사양 템플릿 생성 완료! ==="
echo "템플릿 ID: $VM_ID"
echo "템플릿 이름: $VM_NAME"
echo "사양:"
echo "  - CPU: 16 cores"
echo "  - RAM: 32GB"
echo "  - 디스크: 300GB"
echo "  - QEMU Guest Agent 활성화"
echo "  - SSH 패스워드 인증 허용 (ubuntu/cloud1234)"
echo "  - 디스크 자동 확장"