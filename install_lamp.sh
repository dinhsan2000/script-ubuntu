#!/bin/bash

set -e

# Check Ubuntu version
if ! command -v lsb_release &> /dev/null; then
    UBUNTU_VERSION=$(grep "VERSION_ID" /etc/os-release | cut -d'"' -f2)
else
    UBUNTU_VERSION=$(lsb_release -rs)
fi
SUPPORTED_PHP_VERSION="20.04 22.04"

# Prompt for PHP version
read -p "Enter PHP version to install (e.g., 8.1, 8.2): " PHP_VERSION

# Prompt for domain name
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

# Prompt for MySQL remote user option
read -p "Do you want to create a MySQL remote user? (y/n): " CREATE_REMOTE_USER

# Get system resources
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM / 1024))
CPU_CORES=$(nproc)

# Calculate PHP-FPM settings
MAX_CHILDREN=$((TOTAL_RAM_MB / 50))
if [[ $MAX_CHILDREN -lt $CPU_CORES ]]; then
    MAX_CHILDREN=$CPU_CORES
fi
START_SERVERS=$((MAX_CHILDREN / 2))
MIN_SPARE_SERVERS=$((START_SERVERS / 2))
MAX_SPARE_SERVERS=$((START_SERVERS * 2))

# Function to install Nginx
install_nginx() {
    echo "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    
    echo "Creating Nginx configuration for $DOMAIN_NAME..."
    NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN_NAME"
    sudo cat > "$NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    root /var/www/$DOMAIN_NAME/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    sudo ln -s "$NGINX_CONFIG" /etc/nginx/sites-enabled/
    sudo mkdir -p /var/www/$DOMAIN_NAME/public
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/$DOMAIN_NAME/public/index.php > /dev/null
    sudo chown -R www-data:www-data /var/www/$DOMAIN_NAME
    sudo chmod -R 755 /var/www/$DOMAIN_NAME
    sudo systemctl restart nginx
    echo "Nginx configuration for $DOMAIN_NAME created and enabled."
}

# Function to install PHP
install_php() {
    echo "Installing PHP $PHP_VERSION..."
    sudo apt update
    
    if [[ ! " $SUPPORTED_PHP_VERSION " =~ " $UBUNTU_VERSION " ]]; then
        echo "Unsupported Ubuntu version for default PHP. Adding Ondrej repository..."
        sudo add-apt-repository -y ppa:ondrej/php
        sudo apt update
    fi
    
    sudo apt install -y php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-curl php$PHP_VERSION-zip php$PHP_VERSION-mysql php$PHP_VERSION-bcmath php$PHP_VERSION-tokenizer php$PHP_VERSION-ctype php$PHP_VERSION-fileinfo php$PHP_VERSION-opcache php$PHP_VERSION-readline php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-soap php$PHP_VERSION-redis
    sudo systemctl enable php$PHP_VERSION-fpm
    sudo systemctl start php$PHP_VERSION-fpm
    
    echo "Configuring PHP-FPM to use only TCP socket and optimize settings..."
    PHP_FPM_CONF="/etc/php/$PHP_VERSION/fpm/pool.d/www.conf"
    sudo sed -i "s|^listen = .*|listen = 127.0.0.1:9000|" "$PHP_FPM_CONF"
    sudo sed -i '/^listen = /d' "$PHP_FPM_CONF"
    sudo sed -i "s/^pm\.max_children.*/pm.max_children = $MAX_CHILDREN/" "$PHP_FPM_CONF"
    sudo sed -i "s/^pm\.start_servers.*/pm.start_servers = $START_SERVERS/" "$PHP_FPM_CONF"
    sudo sed -i "s/^pm\.min_spare_servers.*/pm.min_spare_servers = $MIN_SPARE_SERVERS/" "$PHP_FPM_CONF"
    sudo sed -i "s/^pm\.max_spare_servers.*/pm.max_spare_servers = $MAX_SPARE_SERVERS/" "$PHP_FPM_CONF"
    sudo systemctl restart php$PHP_VERSION-fpm
}

# Function to install Redis
install_redis() {
    echo "Installing Redis..."
    sudo apt update
    sudo apt install -y redis-server
    sudo systemctl enable redis
    sudo systemctl start redis
    echo "Redis installation complete."
}

# Function to install Supervisord
install_supervisord() {
    echo "Installing Supervisord..."
    sudo apt update
    sudo apt install -y supervisor
    sudo systemctl enable supervisor
    sudo systemctl start supervisor
    echo "Supervisord installation complete."
}

# Function to install MySQL and create remote user
install_mysql() {
    echo "Installing MySQL..."
    sudo apt update
    sudo apt install -y mysql-server
    sudo systemctl enable mysql
    sudo systemctl start mysql
    
    echo "Generating MySQL root password..."
    ROOT_PASS=$(openssl rand -base64 16)
    echo "Generated MySQL root password: $ROOT_PASS"
    echo "root:$ROOT_PASS" > mysql_credentials.txt
    
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    if [[ "$CREATE_REMOTE_USER" == "y" ]]; then
        echo "Creating MySQL remote user..."
        REMOTE_USER="remote_user"
        REMOTE_PASS=$(openssl rand -base64 16)
        echo "Generated MySQL remote user password: $REMOTE_PASS"
        echo "remote_user:$REMOTE_PASS" >> mysql_credentials.txt
        
        sudo mysql -e "CREATE USER '$REMOTE_USER'@'%' IDENTIFIED BY '$REMOTE_PASS';"
        sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_USER'@'%' WITH GRANT OPTION;"
        sudo mysql -e "FLUSH PRIVILEGES;"
    fi
    
    echo "MySQL root and remote user credentials saved in mysql_credentials.txt"
}

# Display menu
echo "Select the software you want to install (separate multiple choices with spaces):"
echo "1) Nginx"
echo "2) PHP"
echo "3) MySQL"
echo "4) Redis"
echo "5) Supervisord"
echo "6) Exit"
read -p "Enter your choices: " choices

for choice in $choices; do
    case $choice in
        1) install_nginx &;;
        2) install_php &;;
        3) install_mysql &;;
        4) install_redis &;;
        5) install_supervisord &;;
        6) exit 0;;
        *) echo "Invalid option: $choice";;
    esac
    wait
    echo "--------------------------------------"
done