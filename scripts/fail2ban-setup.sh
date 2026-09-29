#!/usr/bin/env bash

set -euo pipefail

FAIL2BAN_PACKAGE="fail2ban"
FAIL2BAN_SERVICE="fail2ban"
JAIL_CONFIG="/etc/fail2ban/jail.d/sshd.local"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v dnf &>/dev/null; then
    echo "dnf is not installed."
    exit 1
fi

if ! rpm -q "${FAIL2BAN_PACKAGE}" &>/dev/null; then
    dnf install -y "${FAIL2BAN_PACKAGE}"
else
    echo "Fail2Ban is already installed."
fi

if ! command -v firewall-cmd &>/dev/null; then
    echo "firewalld is not installed."
    exit 1
fi

systemctl enable --now firewalld

mkdir -p "$(dirname "${JAIL_CONFIG}")"

cat > "${JAIL_CONFIG}" <<'EOF_CONFIG'
[sshd]

enabled = true
backend = systemd
journalmatch = _SYSTEMD_UNIT=sshd.service

banaction = firewallcmd-rich-rules

maxretry = 5
findtime = 10m
bantime = 1h
EOF_CONFIG

fail2ban-client -t

systemctl enable --now "${FAIL2BAN_SERVICE}"

echo "Fail2Ban setup completed successfully."
echo "Service status: $(systemctl is-active "${FAIL2BAN_SERVICE}")"
echo "Enabled at boot: $(systemctl is-enabled "${FAIL2BAN_SERVICE}")"
echo "Configured jail: sshd"
