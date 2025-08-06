proxmox_api_url      = "https://192.168.135.10:8006/api2/json"
proxmox_user         = "root@pam"
proxmox_password     = "cloud1234"
proxmox_tls_insecure = true

# VM 사양 설정
vm_disk_size = 300  # 300GB 디스크
vm_memory    = 32768 # 32GB 메모리 (32 * 1024)
vm_cores     = 16   # 16개 CPU 코어