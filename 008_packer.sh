#!/usr/bin/env bash

source /etc/kolla/admin-openrc.sh
apt-get install unzip -y
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/packer/1.4.4/packer_1.4.4_linux_arm64.zip
unzip -u packer_1.4.4_linux_arm64.zip
rm -rf packer_1.4.4_linux_arm64.zip
chmod +x /usr/local/bin/packer
/usr/local/bin/packer --version
exit
