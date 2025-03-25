# Install LAMP Stack on Ubuntu

This guide will help you install and configure Nginx, PHP, MySQL, Redis, and Supervisord on your Ubuntu system.

## Prerequisites

Before running the installation script, make sure your system is up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

Ensure `curl` is installed:

```bash
sudo apt install -y curl
```

## Installation Instructions

To download and execute the installation script, run:

```bash
curl -s https://raw.githubusercontent.com/dinhsan2000/script-ubuntu/main/install_lamp.sh | bash
```

If you prefer to download and inspect the script before running it:

```bash
curl -O https://raw.githubusercontent.com/dinhsan2000/script-ubuntu/main/install_lamp.sh
chmod +x install_lamp.sh
./install_lamp.sh
```

## Features

- **Nginx** installation and automatic configuration for a specified domain.
- **PHP** installation with a selectable version and common extensions.
- **MySQL** installation with secure root password setup and a remote user.
- **Redis** installation for caching.
- **Supervisord** installation for process management.
- **Optimized PHP-FPM configuration** using TCP sockets.
- **Automatic system resource detection** for PHP-FPM tuning.

## Usage

When running the script, you will be prompted to select components for installation. Simply enter the corresponding numbers separated by spaces.

For example, to install Nginx, PHP, and MySQL:

```bash
1 2 3
```

## MySQL Credentials

After installation, MySQL root and remote user credentials will be stored in `mysql_credentials.txt`. Make sure to secure this file properly.

## Post-Installation

After installation, restart the services to ensure everything is running correctly:

```bash
sudo systemctl restart nginx php<version>-fpm mysql redis supervisor
```

To check the status of services:

```bash
sudo systemctl status nginx php<version>-fpm mysql redis supervisor
```

## Troubleshooting

If you encounter issues, check the logs:

```bash
sudo journalctl -xe
```

For service-specific logs:

```bash
sudo systemctl status nginx
sudo systemctl status php<version>-fpm
sudo systemctl status mysql
sudo systemctl status redis
sudo systemctl status supervisor
```

## Uninstallation

To remove installed components:

```bash
sudo apt remove --purge nginx php* mysql-server redis-server supervisor -y
```

To clean up configuration files:

```bash
sudo rm -rf /etc/nginx /etc/php /etc/mysql /etc/redis /etc/supervisor
```

---

🚀 **Enjoy your optimized LAMP stack on Ubuntu!** 🚀

