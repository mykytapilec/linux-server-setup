#!/usr/bin/env bash

set -euo pipefail

TIMEZONE="Europe/Warsaw"
HOSTNAME="linux-server-setup"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v timedatectl &>/dev/null; then
    echo "timedatectl is not available."
    exit 1
fi

if ! command -v hostnamectl &>/dev/null; then
    echo "hostnamectl is not available."
    exit 1
fi

timedatectl set-timezone "${TIMEZONE}"
hostnamectl set-hostname "${HOSTNAME}"

echo "Server configuration completed successfully."
echo "Timezone: $(timedatectl show --property=Timezone --value)"
echo "Hostname: $(hostnamectl hostname)"
