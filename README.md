# Linux Server Setup

A practical Linux server setup project based on Amazon Linux 2023 and an AWS EC2 instance.

This project is based on the [Linux Server Setup](https://roadmap.sh/projects/linux-server-setup) project from roadmap.sh.

The project demonstrates how to configure, secure, maintain, and verify a Linux server using reproducible Bash scripts and standard Linux administration tools.

## Requirements

* Amazon Linux 2023
* Root or sudo access
* An SSH key pair
* A running EC2 instance or another accessible Linux server
* `dnf`
* `systemd`
* `firewalld`

## Project Structure

```
.
├── scripts/
│   ├── server-user-setup.sh
│   ├── firewall-setup.sh
│   ├── system-updates-setup.sh
│   ├── web-server-setup.sh
│   ├── fail2ban-setup.sh
│   ├── server-configuration-setup.sh
│   ├── service-management-setup.sh
│   ├── log-inspection.sh
│   └── server-verification.sh
├── .gitignore
└── README.md
```

## Server User Setup

The `server-user-setup.sh` script configures an administrator account named `admin`.

The script:

* Creates the `admin` user if it does not already exist.
* Adds `admin` to the `wheel` group.
* Creates the SSH directory and `authorized_keys` file.
* Sets secure SSH file permissions.
* Disables SSH root login.
* Validates the SSH daemon configuration.
* Reloads the SSH daemon.

Run the script with sudo:

```
sudo ./scripts/server-user-setup.sh
```

The script does not create or store passwords or private SSH keys.

## SSH Key Configuration

Add the administrator's public SSH key to:

```
/home/admin/.ssh/authorized_keys
```

The file must be owned by `admin` and have permissions `600`.

The SSH directory must have permissions `700`.

Example:

```
sudo chown -R admin:admin /home/admin/.ssh
sudo chmod 700 /home/admin/.ssh
sudo chmod 600 /home/admin/.ssh/authorized_keys
```

## Administrator Password

Set the `admin` password separately:

```
sudo passwd admin
```

The password is not stored in this repository.

## SSH Hardening

The project disables direct SSH access for the root account and disables password-based SSH authentication.

The effective SSH configuration should contain:

```
permitrootlogin no
passwordauthentication no
pubkeyauthentication yes
```

Check the effective configuration:

```
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|pubkeyauthentication)'
```

Check the SSH service:

```
sudo systemctl is-active sshd
```

Expected result:

```
active
```

## Firewall Configuration

Amazon Linux 2023 uses `firewalld` for host-based firewall management.

The `firewall-setup.sh` script configures the `public` firewall zone and allows SSH access.

The web server setup additionally enables HTTP access.

Run:

```
sudo ./scripts/firewall-setup.sh
```

Check the firewall:

```
sudo firewall-cmd --zone=public --list-services
```

Expected services include:

```
ssh http
```

The AWS EC2 security group should also restrict SSH access to trusted source IP addresses where appropriate.

## System Updates

The `system-updates-setup.sh` script configures automatic package updates using `dnf-automatic`.

The script:

* Installs `dnf-automatic` if necessary.
* Enables automatic package installation.
* Enables and starts the automatic update timer.

Run:

```
sudo ./scripts/system-updates-setup.sh
```

Check the timer:

```
sudo systemctl status dnf-automatic-install.timer
```

Check the automatic update configuration:

```
grep '^apply_updates' /etc/dnf/automatic.conf
```

Expected result:

```
apply_updates = yes
```

Amazon Linux release upgrades are treated separately from regular package updates.

## Web Server

The `web-server-setup.sh` script installs and configures Nginx.

The script:

* Installs Nginx if necessary.
* Validates the Nginx configuration.
* Enables Nginx at boot.
* Starts Nginx.
* Allows HTTP traffic through `firewalld`.

Run:

```
sudo ./scripts/web-server-setup.sh
```

Check the service:

```
sudo systemctl is-active nginx
sudo systemctl is-enabled nginx
```

Validate the configuration:

```
sudo nginx -t
```

Test the local HTTP response:

```
curl -I http://localhost
```

## Fail2Ban

The `fail2ban-setup.sh` script configures Fail2Ban to protect SSH from repeated failed authentication attempts.

The SSH jail uses the systemd journal as its log backend and integrates with `firewalld`.

The default configuration includes:

```
maxretry = 5
findtime = 10m
bantime = 1h
```

Run:

```
sudo ./scripts/fail2ban-setup.sh
```

Check Fail2Ban:

```
sudo fail2ban-client status
```

Check the SSH jail:

```
sudo fail2ban-client status sshd
```

## Server Configuration

The `server-configuration-setup.sh` script configures the server timezone and hostname.

The configured values are:

```
Timezone: Europe/Warsaw
Hostname: linux-server-setup
```

Run:

```
sudo ./scripts/server-configuration-setup.sh
```

Check the timezone:

```
timedatectl
```

Check the hostname:

```
hostnamectl
```

## Service Management

The `service-management-setup.sh` script demonstrates basic systemd service management for Nginx.

The script:

* Validates the Nginx configuration.
* Enables Nginx at boot.
* Starts Nginx.
* Reports the current service state.

Run:

```
sudo ./scripts/service-management-setup.sh
```

Check the service:

```
sudo systemctl status nginx
```

## Log Inspection

The `log-inspection.sh` script provides a quick overview of important server logs.

It displays:

* Recent system journal entries.
* Recent SSH journal entries.
* Recent Nginx journal entries.
* Available log files and directories.
* Nginx log files.
* The Fail2Ban log file.

Run:

```
sudo ./scripts/log-inspection.sh
```

The script is read-only and does not modify server configuration.

## Server Verification

The `server-verification.sh` script performs a final read-only verification of the server configuration.

It checks:

* Administrator user and `wheel` group membership.
* SSH hardening.
* `firewalld` status and configuration.
* Fail2Ban status and SSH jail.
* Nginx configuration and service status.
* Local HTTP response.
* Automatic update configuration and timer.
* Server timezone and hostname.
* SSH and HTTP listening ports.

Run:

```
sudo ./scripts/server-verification.sh
```

A successful verification ends with:

```
Passed checks: 24
Failed checks: 0
Server verification completed successfully.
```

## Security Notes

* Never commit private SSH keys to the repository.
* Never store server passwords in the repository.
* Restrict SSH access using the server's firewall and cloud security group.
* Use SSH keys instead of password authentication.
* Keep root SSH login disabled.
* Test SSH configuration changes before reloading the SSH daemon.
* Keep a separate SSH session open while changing SSH configuration to avoid locking yourself out.
* Review server logs regularly.
* Keep the operating system and installed packages updated.

## Implementation Notes

This project targets Amazon Linux 2023 rather than Ubuntu.

Therefore, some roadmap requirements are implemented using Amazon Linux equivalents:

| Requirement        | Implementation  |
| ------------------ | --------------- |
| Package management | `dnf`           |
| Firewall           | `firewalld`     |
| Automatic updates  | `dnf-automatic` |
| Service management | `systemd`       |
| Web server         | Nginx           |
| SSH protection     | Fail2Ban        |

## License

This project is for educational and practical server administration purposes.
