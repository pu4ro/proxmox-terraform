# Example 1: Create a template from ISO
module "ubuntu_template" {
  source = "./modules/template"
  
  template_name    = "ubuntu-22.04-template"
  target_node      = "proxmox-node1"
  template_id      = 9000
  iso_file         = "local:iso/ubuntu-22.04-server-amd64.iso"
  
  cores    = 2
  memory   = 2048
  disk_size = "20G"
  storage   = "local-lvm"
  
  proxmox_api_url = var.proxmox_api_url
  proxmox_user    = var.proxmox_user
  proxmox_token   = var.proxmox_password
}

# Example 2: Create VM from template
module "web_server" {
  source = "./modules/vm"
  
  vm_name       = "web-server-01"
  target_node   = "proxmox-node1"
  template_name = "ubuntu-22.04-template"
  vm_id         = 100
  
  cores    = 4
  memory   = 4096
  disk_size = "40G"
  
  ip_address = "192.168.1.100"
  gateway    = "192.168.1.1"
  nameserver = "8.8.8.8"
  
  cloud_init_user     = "ubuntu"
  cloud_init_password = "your-secure-password"
  ssh_public_keys     = file("~/.ssh/id_rsa.pub")
}

# Example 3: Create multiple VMs
module "app_servers" {
  source = "./modules/vm"
  count  = 3
  
  vm_name       = "app-server-${count.index + 1}"
  target_node   = "proxmox-node1"
  template_name = "ubuntu-22.04-template"
  vm_id         = 200 + count.index
  
  cores    = 2
  memory   = 2048
  disk_size = "20G"
  
  ip_address = "192.168.1.${200 + count.index}"
  gateway    = "192.168.1.1"
  nameserver = "8.8.8.8"
  
  cloud_init_user     = "ubuntu"
  cloud_init_password = "your-secure-password"
  ssh_public_keys     = file("~/.ssh/id_rsa.pub")
}