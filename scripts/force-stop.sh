#!/usr/bin/env bash
set -euo pipefail

# Usage: force-stop.sh <api_url> <username> <password> <node> <vmid> [insecure]
# Example: force-stop.sh https://pve:8006/api2/json root@pam 'pass' pvenode 106 insecure

API_URL=${1:?api_url required, like https://host:8006/api2/json}
USERNAME=${2:?username required}
PASSWORD=${3:?password required}
NODE=${4:?node required}
VMID=${5:?vmid required}
INSECURE=${6:-}

CURL_OPTS=("-sS")
if [[ -n "${INSECURE}" ]]; then
  CURL_OPTS+=("-k")
fi

login() {
  curl "${CURL_OPTS[@]}" \
    -X POST \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "username=${USERNAME}&password=${PASSWORD}" \
    "${API_URL}/access/ticket"
}

extract_json_field() {
  # Poor-man JSON field extractor: extract first occurrence of "key":"value"
  local key=$1
  sed -n "s/.*\"${key}\"\s*:\s*\"\([^\"]*\)\".*/\1/p"
}

STOP_ENDPOINT="${API_URL}/nodes/${NODE}/qemu/${VMID}/status/stop"
UNLOCK_ENDPOINT="${API_URL}/nodes/${NODE}/qemu/${VMID}/unlock"

echo "[force-stop] Requesting ticket for VMID ${VMID} on node ${NODE}..." >&2
LOGIN_JSON=$(login)

# Try to parse CSRFPreventionToken and ticket without jq
TICKET=$(echo "${LOGIN_JSON}" | extract_json_field ticket)
CSRF=$(echo "${LOGIN_JSON}" | extract_json_field CSRFPreventionToken)

if [[ -z "${TICKET}" || -z "${CSRF}" ]]; then
  echo "[force-stop] ERROR: Failed to obtain ticket/CSRF token from Proxmox API" >&2
  echo "Response: ${LOGIN_JSON}" >&2
  exit 1
fi

attempt=1
max_attempts=5
while :; do
  echo "[force-stop] Attempt ${attempt}/${max_attempts}: unlock ${NODE}/${VMID}" >&2
  UCODE=$(curl "${CURL_OPTS[@]}" -o /dev/null -w "%{http_code}" -X POST \
    -H "CSRFPreventionToken: ${CSRF}" --cookie "PVEAuthCookie=${TICKET}" \
    "${UNLOCK_ENDPOINT}" || true)
  echo "[force-stop] unlock HTTP ${UCODE}" >&2

  echo "[force-stop] Attempt ${attempt}/${max_attempts}: stop ${NODE}/${VMID}" >&2
  HTTP_CODE=$(curl "${CURL_OPTS[@]}" \
    -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "CSRFPreventionToken: ${CSRF}" \
    --cookie "PVEAuthCookie=${TICKET}" \
    "${STOP_ENDPOINT}")

  if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "202" || "${HTTP_CODE}" == "204" ]]; then
    echo "[force-stop] Stop accepted (HTTP ${HTTP_CODE})." >&2
    break
  fi

  if (( attempt >= max_attempts )); then
    echo "[force-stop] ERROR: stop request failed after ${max_attempts} attempts (last HTTP ${HTTP_CODE})." >&2
    exit 1
  fi

  sleep 3
  attempt=$((attempt+1))
done

exit 0
