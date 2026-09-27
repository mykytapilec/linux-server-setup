# Linux Server Setup

A practical Linux server setup project based on Amazon Linux 2023.

This project is based on the [Linux Server Setup](https://roadmap.sh/projects/linux-server-setup) project from roadmap.sh.

The project documents and automates the initial configuration of a Linux server, including administrator user setup, SSH access, and basic SSH hardening.

## Requirements

* Amazon Linux 2023
* Root or sudo access
* An SSH key pair
* A running EC2 instance or another accessible Linux server

## Project Structure

```text
.
├── scripts/
│   └── server-user-setup.sh
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

```bash
sudo ./scripts/server-user-setup.sh
```

The script does not create or store passwords or private SSH keys.

## SSH Key Configuration

Add the administrator's public SSH key to:

```text
/home/admin/.ssh/authorized_keys
```

The file must be owned by `admin` and have permissions `600`.

The SSH directory must have permissions `700`.

Example:

```bash
sudo chown -R admin:admin /home/admin/.ssh
sudo chmod 700 /home/admin/.ssh
sudo chmod 600 /home/admin/.ssh/authorized_keys
```

## Administrator Password

Set the `admin` password separately:

```bash
sudo passwd admin
```

The password is not stored in this repository.

## SSH Hardening

The project disables direct SSH access for the root account:

```text
PermitRootLogin no
```

The SSH daemon configuration is validated before it is reloaded.

Check the effective SSH configuration:

```bash
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|pubkeyauthentication)'
```

Expected configuration:

```text
permitrootlogin no
passwordauthentication no
pubkeyauthentication yes
```

Check the SSH service:

```bash
sudo systemctl is-active sshd
```

Expected result:

```text
active
```

## Verification

Verify that the administrator account exists:

```bash
id admin
```

Verify sudo access:

```bash
sudo whoami
```

Expected result:

```text
root
```

Verify SSH access from another terminal:

```bash
ssh -i /path/to/private-key.pem admin@SERVER_IP
```

A successful connection confirms that the administrator can access the server using the configured SSH key.

## Security Notes

* Never commit private SSH keys to the repository.
* Never store server passwords in the repository.
* Restrict SSH access using the server's firewall or cloud security group.
* Test SSH configuration changes before reloading the SSH daemon.
* Keep a separate SSH session open while changing SSH configuration to avoid locking yourself out.

## License

This project is for educational and practical server administration purposes.
