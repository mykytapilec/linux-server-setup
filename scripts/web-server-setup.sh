#!/usr/bin/env bash

set -euo pipefail

NGINX_SERVICE="nginx"
FIREWALL_ZONE="public"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v dnf &>/dev/null; then
    echo "dnf is not installed."
    exit 1
fi

if ! rpm -q nginx &>/dev/null; then
    dnf install -y nginx
else
    echo "Nginx is already installed."
fi

nginx -t

systemctl enable --now "${NGINX_SERVICE}"

if ! command -v firewall-cmd &>/dev/null; then
    echo "firewalld is not installed."
    exit 1
fi

systemctl enable --now firewalld

firewall-cmd --zone="${FIREWALL_ZONE}" --add-service=http
firewall-cmd --runtime-to-permanent

echo "Web server setup completed successfully."
echo "Nginx status: $(systemctl is-active "${NGINX_SERVICE}")"
echo "Nginx enabled: $(systemctl is-enabled "${NGINX_SERVICE}")"
echo "HTTP firewall service: $(firewall-cmd --zone="${FIREWALL_ZONE}" --query-service=http)"
