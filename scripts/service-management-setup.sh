#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="nginx"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v systemctl &>/dev/null; then
    echo "systemctl is not available."
    exit 1
fi

if ! command -v nginx &>/dev/null; then
    echo "Nginx is not installed."
    exit 1
fi

nginx -t

systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"

echo "Service management configuration completed successfully."
echo "Service: ${SERVICE_NAME}"
echo "Status: $(systemctl is-active "${SERVICE_NAME}")"
echo "Enabled at boot: $(systemctl is-enabled "${SERVICE_NAME}")"
