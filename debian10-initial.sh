#! /bin/bash
Echo "Begining initial Debian 10 Buster commands"
clear
# Update apt
echo "Updating APT"
apt update
clear
# Install common packages
echo "Installing my commonly used packages"
apt install sudo wget unzip
clear
# Update apt again
echo "Updating APT"
apt update
clear
# Distro Upgrade
echo "Upgrading the disto"
apt dist-upgrade -y
clear
# Allow for SSH
# Calls another script to configure SSH
cd /tmp
wget https://raw.githubusercontent.com/benjameshughes/Scripts/configure_ssh.sh
echo "Configuring SSH..."
(../configure_ssh.sh)
clear
echo "SSH Configured to allow root login"