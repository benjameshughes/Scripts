#! /bin/bash

# Colours
green=\e[1;02m

echo -e "========================================" "$green"
echo -e "Debian System Maintenance Script" "$green"
echo -e "Upgrade the system, remove unused packages, fixes apt etc..." "$green"
echo -e "========================================" "$green"

echo -e "========================================" "$green"
echo -e "Checking apt and fixing broken dependancies" "$green"
echo -e "========================================" "$green"
apt-get check -f

clear

echo -e "========================================" "$green"
echo -e "Updating apt" "$green"
echo -e "========================================" "$green"

apt-get update -y

clear

echo -e "========================================" "$green"
echo -e "Updating distro" "$green"
echo -e "========================================" "$green"

apt-get dist-upgrade -y

clear

echo -e "========================================" "$green"
echo -e "Removing unused packages" "$green"
echo -e "========================================" "$green"

apt-get autoremove -y
apt-get autoclean -y

clear

echo -e "========================================" "$green"
echo -e "Clearing out /tmp/"
echo -e "========================================" "$green"

rm -rf /tmp/*

clear

echo -e "========================================" "$green"
echo -e "System maintenance completed" "$green"
echo -e "========================================" "$green"
