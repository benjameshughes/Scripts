# Latest Wordpress Installation Script
# This script will grab the latest Wordpress zip file, setup MySQL, Setup Apache, and Configure a SSL certifcate with LetsEncrypt
# Ben Hughes
# https://github.com/benjameshughes
# https://shellskill.com
# Version alpha

echo "Updating the system..."
apt update -y
apt dist-upgrade -y
clear

echo "Installing needed packages"
apt update -y
apt install -y unzip nano wget apache2 mysql-server
clear

echo "Installing PHP and needed packages"
apt update -y
apt install php7.3 php7.3-common php7.3-fpm php7.3-json php7.3-opcache php7.3-redline