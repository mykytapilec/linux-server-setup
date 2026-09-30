#!/usr/bin/env bash

set -euo pipefail

EXPECTED_USER="admin"
EXPECTED_TIMEZONE="Europe/Warsaw"
EXPECTED_HOSTNAME="linux-server-setup"
FIREWALL_ZONE="public"
SSH_SERVICE="sshd"
NGINX_SERVICE="nginx"
FAIL2BAN_SERVICE="fail2ban"
UPDATES_TIMER="dnf-automatic-install.timer"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_active_service() {
    local service="$1"

    if systemctl is-active --quiet "${service}"; then
        pass "${service} is active"
    else
        fail "${service} is not active"
    fi
}

check_enabled_service() {
    local service="$1"

    if systemctl is-enabled --quiet "${service}"; then
        pass "${service} is enabled at boot"
    else
        fail "${service} is not enabled at boot"
    fi
}

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

echo "=== User and privilege checks ==="

CURRENT_USER="$(logname 2>/dev/null || true)"

if [[ "${CURRENT_USER}" == "${EXPECTED_USER}" ]]; then
    pass "Administrative user is ${EXPECTED_USER}"
else
    fail "Expected administrative user ${EXPECTED_USER}, got ${CURRENT_USER:-unknown}"
fi

if id -nG "${EXPECTED_USER}" | grep -qw "wheel"; then
    pass "${EXPECTED_USER} belongs to the wheel group"
else
    fail "${EXPECTED_USER} does not belong to the wheel group"
fi

if sudo -n -u root true 2>/dev/null; then
    pass "${EXPECTED_USER} has passwordless sudo for verification"
else
    echo "[INFO] Passwordless sudo check skipped or requires a password."
fi

echo
echo "=== SSH hardening checks ==="

if [[ "$(sshd -T | awk '$1 == "permitrootlogin" {print $2; exit}')" == "no" ]]; then
    pass "Root SSH login is disabled"
else
    fail "Root SSH login is not disabled"
fi

if [[ "$(sshd -T | awk '$1 == "pubkeyauthentication" {print $2; exit}')" == "yes" ]]; then
    pass "SSH public key authentication is enabled"
else
    fail "SSH public key authentication is not enabled"
fi

if [[ "$(sshd -T | awk '$1 == "passwordauthentication" {print $2; exit}')" == "no" ]]; then
    pass "SSH password authentication is disabled"
else
    fail "SSH password authentication is not disabled"
fi

echo
echo "=== Firewall checks ==="

if systemctl is-active --quiet firewalld; then
    pass "firewalld is active"
else
    fail "firewalld is not active"
fi

if systemctl is-enabled --quiet firewalld; then
    pass "firewalld is enabled at boot"
else
    fail "firewalld is not enabled at boot"
fi

if firewall-cmd --zone="${FIREWALL_ZONE}" --query-service=ssh >/dev/null 2>&1; then
    pass "SSH is allowed by the firewall"
else
    fail "SSH is not allowed by the firewall"
fi

if firewall-cmd --zone="${FIREWALL_ZONE}" --query-service=http >/dev/null 2>&1; then
    pass "HTTP is allowed by the firewall"
else
    fail "HTTP is not allowed by the firewall"
fi

echo
echo "=== Fail2Ban checks ==="

check_active_service "${FAIL2BAN_SERVICE}"
check_enabled_service "${FAIL2BAN_SERVICE}"

if fail2ban-client status sshd >/dev/null 2>&1; then
    pass "Fail2Ban SSH jail is active"
else
    fail "Fail2Ban SSH jail is not active"
fi

echo
echo "=== Nginx checks ==="

if nginx -t >/dev/null 2>&1; then
    pass "Nginx configuration is valid"
else
    fail "Nginx configuration is invalid"
fi

check_active_service "${NGINX_SERVICE}"
check_enabled_service "${NGINX_SERVICE}"

if curl --fail --silent --show-error --head http://localhost >/dev/null 2>&1; then
    pass "Nginx responds successfully over HTTP"
else
    fail "Nginx does not respond successfully over HTTP"
fi

echo
echo "=== Automatic update checks ==="

if systemctl is-active --quiet "${UPDATES_TIMER}"; then
    pass "Automatic update timer is active"
else
    fail "Automatic update timer is not active"
fi

if systemctl is-enabled --quiet "${UPDATES_TIMER}"; then
    pass "Automatic update timer is enabled"
else
    fail "Automatic update timer is not enabled"
fi

if grep -Eq '^[[:space:]]*apply_updates[[:space:]]*=[[:space:]]*yes[[:space:]]*$' /etc/dnf/automatic.conf; then
    pass "Automatic package installation is enabled"
else
    fail "Automatic package installation is not enabled"
fi

echo
echo "=== Server configuration checks ==="

if [[ "$(timedatectl show --property=Timezone --value)" == "${EXPECTED_TIMEZONE}" ]]; then
    pass "Timezone is ${EXPECTED_TIMEZONE}"
else
    fail "Timezone is not ${EXPECTED_TIMEZONE}"
fi

if [[ "$(hostnamectl hostname)" == "${EXPECTED_HOSTNAME}" ]]; then
    pass "Hostname is ${EXPECTED_HOSTNAME}"
else
    fail "Hostname is not ${EXPECTED_HOSTNAME}"
fi

echo
echo "=== Listening port checks ==="

if ss -ltn | awk '$4 ~ /:22$/ {found=1} END {exit !found}'; then
    pass "SSH is listening on port 22"
else
    fail "SSH is not listening on port 22"
fi

if ss -ltn | awk '$4 ~ /:80$/ {found=1} END {exit !found}'; then
    pass "HTTP is listening on port 80"
else
    fail "HTTP is not listening on port 80"
fi

echo
echo "=== Verification summary ==="

echo "Passed checks: ${PASS_COUNT}"
echo "Failed checks: ${FAIL_COUNT}"

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    echo "Server verification completed with failures."
    exit 1
fi

echo "Server verification completed successfully."
