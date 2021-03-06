#!/bin/bash

# Original script rom https://hacksncloud.com/2020/01/02/how-to-install-powerdns-and-powerdns-admin-on-debian-buster-updated/
# I added a random password generator. The script then inserts the generated passwords into the .sql files for us in the myself installation

echo "=============================================="
echo "PowerDNS Installer Script"
echo "Original script from: https://hacksncloud.com"
echo "Changed to fit my needs"
echo "Ben Hughes https://github.com/benjameshughes"
echo "=============================================="

# Ask user for the hostname
echo "Is this the correct IP, yes or no (y/n)?"
ip="$(hostname -I)"
echo $ip
read -e ipcorrect
if [ "$ipcorrect" == n }
then
echo "Please enter the correct IP Address"
read -e ip
fi

clear

echo "=============================================="
echo "Upgrading disto and install dependancies"
echo "=============================================="

# Update distro
apt update -y

#Distro upgrade
apt dist-upgrade -y

# Install needed packages and dependancies
apt install -y pwgen unzip wget software-properties-common dirmngr expect
apt install -y git python-pip

# SQL Password variables for installation
pass1=$(pwgen -Bs 10 1)
pass2=$(pwgen -Bs 10 1)

# Change to /tmp and downloaded the needed files
wget https://hacksncloud.com/wp-content/uploads/2020/01/pdns-buster-updated.zip

# Extract zip file
unzip pdns-buster-updated.zip

clear

echo "=============================================="
echo "Editing files..."
echo "=============================================="

# Edit files
sed -i "s/mypassword/$pass1/g" "/tmp/pdns/sql01.sql"
sed -i "s/mypassword/$pass2/g" "/tmp/pdns/sql01.sql"
sed -i "s/pdns.example.com/$ip/g" "/tmp/pdns/powerdns-admin.conf"
sed -i "s/mypassword/$pass1/g" "/tmp/pdns/pdns.local.gmysql.conf"

clear

echo "=============================================="
echo "This is your mysql root password. It will be deleted once script is complete so please make a note of it"
echo "=============================================="

# Echos passwords
echo "First password:" $pass1
echo "Second password:" $pass2

# Allows the user to make a note of the generated password as they will be deleted later
read -p "Press [ENTER] to continue."

clear

echo "=============================================="
echo "Installing and configuring PowerDNS and backend"
echo "=============================================="

# get script absolute path
MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then
	  exit 1
fi

# install and prepare last stable mariadb version
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.liquidtelecom.com/repo/10.4/debian buster main'
apt-get update && apt-get -y install mariadb-server 

# run the secure script to set root password, remove test database and disable remote root user login, you can safely accept the defaults and provide an strong root password when prompted
# mysql_secure_installation
# mysql -u root -p  < ${MY_PATH}/sql01.sql # provide previously set password

mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$pass1') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

# install powerdns and configure db parameters
apt-get -y install pdns-server pdns-backend-mysql
cp ${MY_PATH}/pdns.local.gmysql.conf /etc/powerdns/pdns.d/
# added a sed command for this, less interaction
# vi /etc/powerdns/pdns.d/pdns.local.gmysql.conf # db configuration

# install dnsutils for testing, curl and finally PowerDNS-Admin
apt-get -y install python3-dev dnsutils curl
apt-get -y install -y default-libmysqlclient-dev python-mysqldb libsasl2-dev libffi-dev libldap2-dev libssl-dev libxml2-dev libxslt1-dev libxmlsec1-dev pkg-config
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
apt-get -y install apt-transport-https # needed for https repo
apt-get update 
apt-get -y install yarn
git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /opt/web/powerdns-admin
cd /opt/web/powerdns-admin
pip install virtualenv
virtualenv -p python3 flask
. ./flask/bin/activate
pip install -r requirements.txt
#mysql -u root -p < ${MY_PATH}/sql02.sql
# vi powerdnsadmin/default_config.py
export FLASK_APP=powerdnsadmin/__init__.py
flask db upgrade
flask db migrate -m "Init DB"

# install/update nodejs, needed to use yarn
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs
yarn install --pure-lockfile
flask assets build

# create systemd service file and activate it
mkdir /run/powerdns-admin
chown pdns:pdns /run/powerdns-admin
cp ${MY_PATH}/powerdns-admin.service /etc/systemd/system/
systemctl daemon-reload
systemctl start powerdns-admin
systemctl enable powerdns-admin

# install nginx and configure site
apt-get -y install nginx
cp ${MY_PATH}/powerdns-admin.conf /etc/nginx/sites-enabled/
chown -R pdns:pdns /opt/web/powerdns-admin/powerdnsadmin/static/
nginx -t && service nginx restart

# activate powerdns api, change api-key if needed
echo 'api=yes' >> /etc/powerdns/pdns.conf
echo 'api-key=789456123741852963' >> /etc/powerdns/pdns.conf
echo 'webserver=yes' >> /etc/powerdns/pdns.conf
echo 'webserver-address=0.0.0.0' >> /etc/powerdns/pdns.conf
echo 'webserver-allow-from=0.0.0.0/0,::/0' >> /etc/powerdns/pdns.conf
echo 'webserver-port=8081' >> /etc/powerdns/pdns.conf

service pdns restart

clear

echo "=============================================="
echo "Installation complete. Clearing up..."
echo "=============================================="

# Remove all files

rm $MYPATH/pdns.sh
rm -rf $MYPATH/pdns/*
unset pass1
unset pass2
unset MYPATH

# now go to server_name url and create a firt user account that will be admin
# log in
# configure api access on powerdns-admin
# enjoy
# End of the above if statement
