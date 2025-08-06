#!/bin/bash
# 192.168.135.100~200 범위에서 사용 가능한 IP 찾기

NETWORK="192.168.135"
START_IP=100
END_IP=200

for i in $(seq $START_IP $END_IP); do
    IP="$NETWORK.$i"
    
    # ping으로 IP 확인 (1초 timeout, 1번만)
    if ! ping -c 1 -W 1 "$IP" >/dev/null 2>&1; then
        echo "{\"ip\": \"$IP\"}"
        exit 0
    fi
done

echo "{\"ip\": \"192.168.135.100\"}"
exit 0