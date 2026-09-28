#!/usr/bin/env bash

set -euo pipefail

FIREWALL_ZONE="public"
NETWORK_INTERFACE="ens5"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v firewall-cmd &>/dev/null; then
    echo "firewalld is not installed."
    echo "Install it with: dnf install -y firewalld"
    exit 1
fi

systemctl enable --now firewalld

firewall-cmd --set-default-zone="${FIREWALL_ZONE}"

if ! firewall-cmd --zone="${FIREWALL_ZONE}" --list-interfaces | grep -qw "${NETWORK_INTERFACE}"; then
    firewall-cmd --zone="${FIREWALL_ZONE}" --add-interface="${NETWORK_INTERFACE}"
fi

firewall-cmd --zone="${FIREWALL_ZONE}" --remove-service=mdns || true
firewall-cmd --zone="${FIREWALL_ZONE}" --remove-service=dhcpv6-client || true
firewall-cmd --zone="${FIREWALL_ZONE}" --add-service=ssh

firewall-cmd --runtime-to-permanent

echo "Firewall configuration applied successfully."
echo "Zone: ${FIREWALL_ZONE}"
echo "Interface: ${NETWORK_INTERFACE}"
echo "Allowed service: ssh"
