#!/usr/bin/env bash
set -euo pipefail

# Usage: prestop-from-state.sh <tfvars_json_path>

TFVARS_JSON=${1:-tf/terraform.tfvars.json}

API_URL=$(jq -r .proxmox_api_url "$TFVARS_JSON")
USER=$(jq -r .proxmox_user "$TFVARS_JSON")
PASS=$(jq -r .proxmox_password "$TFVARS_JSON")

terraform state list | grep -F 'proxmox_virtual_environment_vm.ubuntu_vm[' | while read -r ADDR; do
  NODE=$(terraform state show -no-color "$ADDR" | grep 'node_name' | head -n1 | cut -d'=' -f2- | tr -d '"' | xargs || true)
  VMID=$(terraform state show -no-color "$ADDR" | grep 'vm_id' | head -n1 | cut -d'=' -f2- | tr -d '"' | xargs || true)
  if [ -n "${NODE:-}" ] && [ -n "${VMID:-}" ]; then
    echo "[prestop] ${NODE}/${VMID}"
    scripts/force-stop.sh "$API_URL" "$USER" "$PASS" "$NODE" "$VMID" insecure || true
  fi
done

