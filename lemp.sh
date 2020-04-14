# LEMP Stack install on fresh Debian 10
# Ben Hughes https://shellskill.com https://github.com/benjameshughes
# Version alpha
# Date created: 14th April 2020
# Date Modified:

# Variables
mysqlrootpass=$(pwgen -Bs 12 1)
hostname=$(hostname -I)

# Add domain or IP to host file
echo "What is the domain name or IP address?"
read -p hostname
sed "/s/localhost/localhost $hostname/g" "/etc/hosts"
clear
# Update distro
echo "Updating and upgrading the system"
apt update -y
apt autoremove -y
apt autoclean -y
apt dist-upgrade -y
clear
# Install needed packages
echo "Installing needed dependancies"
apt install -y sudo wget pwgen 
clear
# Enable UFW
echo "Configuring firewall"
systemctl enable UFW
if [ $? -eq 0]
then
    echo "Firewall is already running"
    exit 0
else
    echo "Starting firewall"
    exit 1
fi
clear
# Install Nginx
echo "Installing Nginx and enabling at boot"
apt update -y
apt install Nginx
systemctl enable Nginx
if [ $? -eq 0]
then
    echo "Nginx is installed and running!"
    exit 0
    pause
    echo "Press enter to continue LEMP installation"
else
    echo "Nginx has ran into a error please see the logs"
    exit 1
fi
clear

# Setup Firewall rules
echo "Setting up firewall rules"
sudo ufw allow "Nginx HTTP"
clear

# Test to make sure Nginx is accessible
echo "Access the following IP address to check Ngxinx is reachable"
echo "$hostname"
echo "If it is accessible you can continue."
pause
clear

#Install MariaDB
echo "Installing Mariadb Server"
apt-get install -y mariadv-server
clear

# Running mysql_secure_installation
echo "Running mysql_secure_installation and configuring with default. This will also set a root password and print it below"
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$mysqlrootpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF
clear

# Install PHP
echo "Installing PHP"
apt-get install -y php php-fpm php-mysql
clear

# Configure PHP
echo "Configuring PHP for Nginx"
mkdir /var/www/html
chmod -R www-data:www-data /var/www/html
wget
sed "s/domain.com/$hostname/g" "default"
cp default /etc/nginx/sites-available/default_ssl
rm default
ln -s /etc/nginx/sites-available/default_ssl /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
clear

# Install Certbot and configre for our domain
apt-get update -y
apt-get install -y certbot python-certbot-nginx
certbot --nginx

# After completed installation
unset mysqlrootpass
unset hostname
echo "Installation has been successful. Important information available below"
echo "https://$hostname"
echo "Default web folder /www/var/html"
echo "MySQL Root password: $mysqlrootpass Please make a copy of this as there is no record kept anywhere"
echo "Thanks for using my installer https://shellskill.com https://github.com/benjameshughes"