#!/bin/bash
# 템플릿에서 serial 설정 제거하고 수정

VM_ID=9002
echo "템플릿 9002에서 serial 설정 제거 중..."

# 템플릿을 일반 VM으로 전환
qm template $VM_ID --delete

# serial 설정 제거
qm set $VM_ID --delete serial0

# VGA를 std로 설정 (serial 대신)
qm set $VM_ID --vga std

# 다시 템플릿으로 변환
qm template $VM_ID

echo "템플릿 수정 완료!"