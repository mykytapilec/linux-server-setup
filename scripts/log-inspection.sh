#!/usr/bin/env bash

set -euo pipefail

LOG_DIRECTORY="/var/log"
SYSTEM_LOG_LINES=10
SERVICE_LOG_LINES=10

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

if ! command -v journalctl &>/dev/null; then
    echo "journalctl is not available."
    exit 1
fi

echo "=== Recent system journal entries ==="
journalctl --no-pager -n "${SYSTEM_LOG_LINES}"

echo
echo "=== Recent SSH journal entries ==="
journalctl -u sshd --no-pager -n "${SERVICE_LOG_LINES}"

echo
echo "=== Recent Nginx journal entries ==="
journalctl -u nginx --no-pager -n "${SERVICE_LOG_LINES}"

echo
echo "=== Available log files and directories ==="
ls -lah "${LOG_DIRECTORY}"

echo
echo "=== Nginx log directory ==="
if [[ -d "${LOG_DIRECTORY}/nginx" ]]; then
    ls -lah "${LOG_DIRECTORY}/nginx"
else
    echo "Nginx log directory does not exist."
fi

echo
echo "=== Fail2Ban log ==="
if [[ -f "${LOG_DIRECTORY}/fail2ban.log" ]]; then
    ls -lh "${LOG_DIRECTORY}/fail2ban.log"
else
    echo "Fail2Ban log does not exist."
fi
