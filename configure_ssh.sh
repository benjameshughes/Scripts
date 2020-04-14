cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default

wget https://raw.githubusercontent.com/benjameshughes/Scripts/master/templates/ssh/sshd_config

mv sshd_config /etc/ssh/sshd_config

systemctl restart ssh

rm /tmp/sshd_config

cd 