#!/usr/bin/env bash

PACKER_VERSION='1.5.1'

source /etc/kolla/admin-openrc.sh
apt-get install unzip -y
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/packer/$PACKER_VERSION/packer_$PACKER_VERSION_linux_arm64.zip
unzip -u packer_$PACKER_VERSION_linux_arm64.zip
rm -rf packer_$PACKER_VERSION_linux_arm64.zip
chmod +x /usr/local/bin/packer
/usr/local/bin/packer --version
exit
