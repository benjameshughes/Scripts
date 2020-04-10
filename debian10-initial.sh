#! /bin/bash

# Update apt
apt update

# Install common packages
apt install sudo wget

# Update apt again
apt update

# Distro Upgrade
apt dist-upgrade -y

# Allow for SSH
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.old

cd /tmp

wget 

mv sshd_config /etc/ssh/sshd_config

systemctl restart ssh

rm /tmp/sshd_config

cd 