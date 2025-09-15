# Makefile to create Ubuntu templates (22.04 and 24.04) on Proxmox

# Usage examples:
#   make template-22
#   make template-24 PROXMOX_HOST=192.168.135.10 PROXMOX_PASSWORD=cloud1234
#   make template-all

PROXMOX_HOST ?= 192.168.135.10
PROXMOX_PASSWORD ?= cloud1234

.PHONY: help template-22 template-24 template-all

help:
	@echo "Targets:"
	@echo "  template-22   - Create Ubuntu 22.04 template (ID: 9005)"
	@echo "  template-24   - Create Ubuntu 24.04 template (ID: 9007)"
	@echo "  template-all  - Create both 22.04 and 24.04 templates"
	@echo "Variables:"
	@echo "  PROXMOX_HOST      Proxmox node IP/hostname (default: $(PROXMOX_HOST))"
	@echo "  PROXMOX_PASSWORD  Proxmox root password   (default: ****)"
	@echo "Examples:"
	@echo "  make template-22 PROXMOX_HOST=192.168.135.10 PROXMOX_PASSWORD=cloud1234"

template-22:
	@echo "Creating Ubuntu 22.04 template on $(PROXMOX_HOST) ..."
	OS_VERSION=22.04 \
	PROXMOX_HOST=$(PROXMOX_HOST) \
	PROXMOX_PASSWORD=$(PROXMOX_PASSWORD) \
	./create-template-multi-os.sh

template-24:
	@echo "Creating Ubuntu 24.04 template on $(PROXMOX_HOST) ..."
	OS_VERSION=24.04 \
	PROXMOX_HOST=$(PROXMOX_HOST) \
	PROXMOX_PASSWORD=$(PROXMOX_PASSWORD) \
	./create-template-multi-os.sh

template-all: template-22 template-24
	@echo "All templates complete."

