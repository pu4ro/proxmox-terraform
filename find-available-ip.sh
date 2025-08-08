#!/bin/bash
# 192.168.135.30~100 범위에서 사용 가능한 IP들 찾기

NETWORK="192.168.135"
START_IP=30
END_IP=100
VM_INDEX=${1:-0}  # VM 인덱스 (0부터 시작)

# 사용 가능한 IP들을 배열에 저장
available_ips=()

for i in $(seq $START_IP $END_IP); do
    IP="$NETWORK.$i"
    
    # ping으로 IP 확인 (1초 timeout, 1번만)
    if ! ping -c 1 -W 1 "$IP" >/dev/null 2>&1; then
        available_ips+=("$IP")
    fi
done

# VM 인덱스에 해당하는 IP 반환
if [ ${#available_ips[@]} -gt $VM_INDEX ]; then
    echo "{\"ip\": \"${available_ips[$VM_INDEX]}\"}"
else
    # 사용 가능한 IP가 부족한 경우 기본값 + 인덱스
    fallback_ip="$NETWORK.$((START_IP + VM_INDEX))"
    echo "{\"ip\": \"$fallback_ip\"}"
fi

exit 0