#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="admin"
SSH_CONFIG_FILE="/etc/ssh/sshd_config.d/10-hardening.conf"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! id "${ADMIN_USER}" &>/dev/null; then
    useradd -m -s /bin/bash "${ADMIN_USER}"
    echo "Created user: ${ADMIN_USER}"
else
    echo "User already exists: ${ADMIN_USER}"
fi

usermod -aG wheel "${ADMIN_USER}"

SSH_DIR="/home/${ADMIN_USER}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

mkdir -p "${SSH_DIR}"
touch "${AUTHORIZED_KEYS}"

chown -R "${ADMIN_USER}:${ADMIN_USER}" "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
chmod 600 "${AUTHORIZED_KEYS}"

cat > "${SSH_CONFIG_FILE}" <<'EOF_CONFIG'
PermitRootLogin no
EOF_CONFIG

chmod 600 "${SSH_CONFIG_FILE}"

sshd -t
systemctl reload sshd

echo "SSH configuration validated successfully."
echo "SSH service reloaded successfully."
echo "User '${ADMIN_USER}' is configured with sudo access through the wheel group."
echo "Add the administrator's public SSH key to:"
echo "${AUTHORIZED_KEYS}"
echo "Set the administrator password separately with: passwd ${ADMIN_USER}"
