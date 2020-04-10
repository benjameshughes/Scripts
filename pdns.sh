#!/bin/bash

# Password variables for installation
# From top answer https://stackoverflow.com/questions/40326158/generate-password-in-bash-store-in-variable

$ pass1=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
$ pass2=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)

# I added the follow to grab the files needed and make changes to the files

cd /tmp

wget https://hacksncloud.com/wp-content/uploads/2020/01/pdns-buster-updated.zip

# Install unzip, just in case

apt install unzip -y

# Unzip package above

unzip pdns-buster-updated.zip

# Change to directory

cd pdns

# Edit files

sed -i "s /mypassword/$pass1/g" sql01.sql
sed -i "s /mypassword/$pass2/g" sql01.sql

# Echos passwords

echo "First password: $ echo $pass1"
echo "Second password: $ echo $pass2"

read -p "Please copy these passwords for the second part of the installation. Once done press [ENTER] to continue."

# From https://hacksncloud.com/2020/01/02/how-to-install-powerdns-and-powerdns-admin-on-debian-buster-updated/

# get script absolute path
MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then
	  exit 1
fi

# upgrade system and install dependencies
apt-get update && apt-get -y upgrade
apt-get -y install software-properties-common dirmngr
apt-get -y install git python-pip

# install and prepare last stable mariadb version
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.liquidtelecom.com/repo/10.4/debian buster main'
apt-get update && apt-get -y install mariadb-server 

# run the secure script to set root password, remove test database and disable remote root user login, you can safely accept the defaults and provide an strong root password when prompted
mysql_secure_installation
mysql -u root -p < ${MY_PATH}/sql01.sql # provide previously set password

# install powerdns and configure db parameters
apt-get -y install pdns-server pdns-backend-mysql
cp ${MY_PATH}/pdns.local.gmysql.conf /etc/powerdns/pdns.d/
vi /etc/powerdns/pdns.d/pdns.local.gmysql.conf # db configuration

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
mysql -u root -p < ${MY_PATH}/sql02.sql
vi powerdnsadmin/default_config.py
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

# now go to server_name url and create a firt user account that will be admin
# log in
# configure api access on powerdns-admin
# enjoy