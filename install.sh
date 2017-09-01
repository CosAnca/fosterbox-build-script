#!/bin/bash

# /*=================================
# =            VARIABLES            =
# =================================*/
WELCOME_MESSAGE='
 /$$$$$$$$                    /$$                         /$$                          
| $$_____/                   | $$                        | $$                          
| $$     /$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$ | $$$$$$$   /$$$$$$  /$$   /$$
| $$$$$ /$$__  $$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$| $$__  $$ /$$__  $$|  $$ /$$/
| $$__/| $$  \ $$|  $$$$$$   | $$    | $$$$$$$$| $$  \__/| $$  \ $$| $$  \ $$ \  $$$$/ 
| $$   | $$  | $$ \____  $$  | $$ /$$| $$_____/| $$      | $$  | $$| $$  | $$  >$$  $$ 
| $$   |  $$$$$$/ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$      | $$$$$$$/|  $$$$$$/ /$$/\  $$
|__/    \______/ |_______/    \___/   \_______/|__/      |_______/  \______/ |__/  \__/
'

reboot_webserver_helper() {

    sudo systemctl restart php7.0-fpm
    sudo systemctl restart nginx

    echo 'Rebooting your webserver'
}





# /*=========================================
# =            CORE / BASE STUFF            =
# =========================================*/
DEBIAN_FRONTEND=noninteractive
sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo apt-get install -y build-essential
sudo apt-get install -y tcl
sudo apt-get install -y software-properties-common
sudo apt-get -y install vim
sudo apt-get -y install git







# /*=====================================
# =            INSTALL NGINX            =
# =====================================*/

# Install Nginx
sudo apt-get -y install nginx
sudo systemctl enable nginx

# Remove "html" and add public
mv /var/www/html /var/www/public

# Make sure your web server knows you did this...
MY_WEB_CONFIG='server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/public;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}'
echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

sudo systemctl restart nginx









# /*===================================
# =            INSTALL PHP            =
# ===================================*/
sudo apt-get -y install php

# Make PHP and NGINX friends

# FPM STUFF
sudo apt-get -y install php-fpm
sudo systemctl enable php7.0-fpm
sudo systemctl start php7.0-fpm

# Fix path FPM setting
echo 'cgi.fix_pathinfo = 0' | sudo tee -a /etc/php/7.0/fpm/conf.d/user.ini
sudo systemctl restart php7.0-fpm

# Add index.php to readable file types and enable PHP FPM since PHP alone won't work
MY_WEB_CONFIG='server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/public;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}'
echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

sudo systemctl restart nginx






# /*===================================
# =            PHP MODULES            =
# ===================================*/

# Base Stuff
sudo apt-get -y install php-common
sudo apt-get -y install php-all-dev

# Common Useful Stuff
sudo apt-get -y install php-bcmath
sudo apt-get -y install php-bz2
sudo apt-get -y install php-cgi
sudo apt-get -y install php-cli
sudo apt-get -y install php-fpm
sudo apt-get -y install php-imap
sudo apt-get -y install php-intl
sudo apt-get -y install php-json
sudo apt-get -y install php-mbstring
sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-odbc
sudo apt-get -y install php-pear
sudo apt-get -y install php-pspell
sudo apt-get -y install php-tidy
sudo apt-get -y install php-xmlrpc
sudo apt-get -y install php-zip

# Enchant
sudo apt-get -y install libenchant-dev
sudo apt-get -y install php-enchant

# LDAP
sudo apt-get -y install ldap-utils
sudo apt-get -y install php-ldap

# CURL
sudo apt-get -y install curl
sudo apt-get -y install php-curl

# GD
sudo apt-get -y install libgd2-xpm-dev
sudo apt-get -y install php-gd

# IMAGE MAGIC
sudo apt-get -y install imagemagick
sudo apt-get -y install php-imagick






# /*===========================================
# =            CUSTOM PHP SETTINGS            =
# ===========================================*/
PHP_USER_INI_PATH=/etc/php/7.0/fpm/conf.d/user.ini

echo 'display_startup_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'display_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'error_reporting = E_ALL' | sudo tee -a $PHP_USER_INI_PATH
echo 'short_open_tag = On' | sudo tee -a $PHP_USER_INI_PATH
reboot_webserver_helper

# Disable PHP Zend OPcache
echo 'opache.enable = 0' | sudo tee -a $PHP_USER_INI_PATH

# Absolutely Force Zend OPcache off...
sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.0/fpm/php.ini
reboot_webserver_helper







# /*================================
# =            PHP UNIT            =
# ================================*/
sudo wget https://phar.phpunit.de/phpunit-6.1.phar
sudo chmod +x phpunit-6.1.phar
sudo mv phpunit-6.1.phar /usr/local/bin/phpunit
reboot_webserver_helper







# /*=============================
# =            MYSQL            =
# =============================*/
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server
sudo mysqladmin -uroot -proot create fosterbox
sudo apt-get -y install php-mysql
reboot_webserver_helper













# /*================================
# =            COMPOSER            =
# ================================*/
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
php composer-setup.php --quiet
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod 755 /usr/local/bin/composer








# /*==================================
# =            BEANSTALKD            =
# ==================================*/
sudo apt-get -y install beanstalkd







# /*==============================
# =            WP-CLI            =
# ==============================*/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp








# /*=============================
# =            NGROK            =
# =============================*/
sudo apt-get install ngrok-client







# /*=================================
# =            MEMCACHED            =
# =================================*/
sudo apt-get -y install memcached
sudo apt-get -y install php-memcached
reboot_webserver_helper







# /*==============================
# =            GOLANG            =
# ==============================*/
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo apt-get -y install golang-go








# /*===============================
# =            MAILHOG            =
# ===============================*/
sudo wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
sudo chmod +x ~/mailhog

# Enable and Turn on
sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=MailHog Service
After=network.service vagrant.mount
[Service]
Type=simple
ExecStart=/usr/bin/env /home/vagrant/mailhog > /dev/null 2>&1 &
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable mailhog
sudo systemctl start mailhog

# Install Sendmail replacement for MailHog
sudo go get github.com/mailhog/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/sendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mail

# Make it work with PHP
echo 'sendmail_path = /usr/bin/mhsendmail' | sudo tee -a /etc/php/7.0/fpm/conf.d/user.ini

reboot_webserver_helper












# /*=======================================
# =            WELCOME MESSAGE            =
# =======================================*/

# Disable default messages by removing execute privilege
sudo chmod -x /etc/update-motd.d/*

# Set the new message
echo "$WELCOME_MESSAGE" | sudo tee /etc/motd











# /*====================================
# =            YOU ARE DONE            =
# ====================================*/
echo 'Booooooooom! We are done. You are a hero. I love you.'
