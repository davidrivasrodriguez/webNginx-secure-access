#!/bin/bash

# Update packages
sudo apt-get update

# # Install necessary packages
sudo apt-get install -y nginx git ufw

# Start Nginx service
sudo systemctl start nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Create directory for the website
sudo mkdir -p /var/www/firstweb/html

# Clone the repository of the first website
sudo git clone https://github.com/cloudacademy/static-website-example.git /var/www/firstweb/html

# Set the permissions
sudo chown -R www-data:www-data /var/www/firstweb/html
sudo chmod -R 755 /var/www/firstweb

# Create an Nginx configuration file
cat <<EOL | sudo tee /etc/nginx/sites-available/firstweb
server {
    listen 80;
    listen [::]:80;
    root /var/www/firstweb/html;
    index index.html index.htm;
    server_name firstweb;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Create a symbolic link for the Nginx configuration
sudo ln -s /etc/nginx/sites-available/firstweb /etc/nginx/sites-enabled/

# Firewall configuration for Nginx to allow HTTP traffic
sudo ufw allow 'Nginx HTTP'

# Verify Nginx configuration
sudo nginx -t

# Restart Nginx to apply the changes
sudo systemctl restart nginx

############### SECOND PART ####################

# Install ftp
sudo apt-get install -y vsftpd

# Start ftp service
sudo systemctl start vsftpd

# Enable ftp to start on boot
sudo systemctl enable vsftpd

# Create directory for the website
sudo mkdir -p /var/www/rockclimbing/html

# Clone the repository of the second website
sudo git clone https://github.com/davidrivasrodriguez/rock-climbing-web.git /var/www/rockclimbing/html

# Set permissions for the website directory
sudo chown -R www-data:www-data /var/www/rockclimbing
sudo chmod -R 775 /var/www/rockclimbing/html

# Create an Nginx configuration for the website
cat <<EOL | sudo tee /etc/nginx/sites-available/rockclimbing
server {
    listen 80;
    listen [::]:80;
    root /var/www/rockclimbing/html;
    index index.html index.htm;
    server_name rockclimbing;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Create a symbolic link to enable the configuration in Nginx
sudo ln -s /etc/nginx/sites-available/rockclimbing /etc/nginx/sites-enabled/

# Verify and restart Nginx to apply the changes
sudo nginx -t && sudo systemctl restart nginx

# Generate certificates for vsftpd
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/certs/vsftpd.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=rockclimbing"

# Configure vsftpd for secure connections with the provided SSL configurations
cat <<EOL | sudo tee /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
rsa_cert_file=/etc/ssl/certs/vsftpd.crt
rsa_private_key_file=/etc/ssl/private/vsftpd.key
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
pasv_min_port=40000
pasv_max_port=50000
local_root=/var/www/rockclimbing/html
EOL

# Restart vsftpd service to apply tcat he configuration
sudo systemctl restart vsftpd

# Create an SFTP user and set the home directory to /var/www/rockclimbing/html
sudo useradd -m ftpuser -d /var/www/rockclimbing/html
echo "ftpuser:ftpuser" | sudo chpasswd

# Add ftpuser to the www-data group for write permissions on the website directory
sudo usermod -aG www-data ftpuser

# Change the owner of the html directory to ftpuser and www-data
sudo chown ftpuser:www-data /var/www/rockclimbing/html
sudo chmod -R 775 /var/www/rockclimbing/html



############### THIRD PART ####################

# Create new users
sudo adduser david
echo "david:david" | sudo chpasswd
sudo adduser rivas
echo "rivas:rivas" | sudo chpasswd

# Create .htpasswd file for authentication
sudo sh -c "echo -n 'david:' > /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 'david' >> /etc/nginx/.htpasswd"
sudo sh -c "echo -n 'rivas:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 'rivas' >> /etc/nginx/.htpasswd"

# Add authentication to the Nginx configuration
cat <<EOL | sudo tee /etc/nginx/sites-available/rockclimbing
server {
    listen 80;
    listen [::]:80;
    root /var/www/rockclimbing/html;
    index index.html index.htm;
    server_name rockclimbing;

    location / {         
        try_files \$uri \$uri/ =404;
    }

    location /assets/pages/competitionsPage.html {
        satisfy all;

        allow 192.168.57.1;
        deny all;

        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;

        try_files \$uri \$uri/ =404;
    }

    location /assets/pages/contactPage.html {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files \$uri \$uri/ =404;
    }

}
EOL

# Restart Nginx to apply the changes
sudo systemctl restart nginx


############### FOUTH PART ####################

# Create a directory for the secure website
sudo mkdir -p /var/www/koyo/html

# Clone the repository of the secure website
sudo git clone https://github.com/davidrivasrodriguez/Koyo-restaurant.git /var/www/koyo/html

# Set permissions for the secure website directory
sudo chown -R www-data:www-data /var/www/koyo
sudo chmod -R 755 /var/www/koyo/html

# Generate a self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 -keyout /etc/ssl/private/koyo.key \
  -out /etc/ssl/certs/koyo.crt \
  -subj "/C=ES/ST=Andalucia/L=Granada/O=IZV/OU=WEB/CN=koyo"

# Create an Nginx configuration for the secure website
cat <<EOL | sudo tee /etc/nginx/sites-available/koyo
server {
    listen 80;
    listen 443 ssl;
    server_name koyo;

    root /var/www/koyo/html;
    index index.html index.htm;

    ssl_certificate /etc/ssl/certs/koyo.crt;
    ssl_certificate_key /etc/ssl/private/koyo.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;


    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Create a symbolic link to enable the configuration in Nginx
sudo ln -s /etc/nginx/sites-available/koyo /etc/nginx/sites-enabled/

# Adjust firewall rules to allow HTTPS traffic
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw --force enable


# Verify and restart Nginx to apply the changes
sudo nginx -t 
sudo systemctl restart nginx