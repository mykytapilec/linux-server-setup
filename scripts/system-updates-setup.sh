#!/usr/bin/env bash

set -euo pipefail

DNF_AUTOMATIC_CONFIG="/etc/dnf/automatic.conf"
DNF_AUTOMATIC_TIMER="dnf-automatic-install.timer"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v dnf &>/dev/null; then
    echo "dnf is not installed."
    exit 1
fi

if ! rpm -q dnf-automatic &>/dev/null; then
    dnf install -y dnf-automatic
fi

sed -i 's/^apply_updates = no$/apply_updates = yes/' "${DNF_AUTOMATIC_CONFIG}"

systemctl enable --now "${DNF_AUTOMATIC_TIMER}"

echo "Automatic system updates configured successfully."
echo "Configuration: ${DNF_AUTOMATIC_CONFIG}"
echo "Timer: ${DNF_AUTOMATIC_TIMER}"
echo "Automatic installation: enabled"
