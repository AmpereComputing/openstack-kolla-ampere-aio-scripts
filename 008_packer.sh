#!/usr/bin/env bash

PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/008_packer.log
exec >> $LOGFILE 2>&1

PACKER_VERSION='1.5.4'

source /etc/kolla/admin-openrc.sh
apt-get install unzip -y
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip
unzip -u packer_${PACKER_VERSION}_linux_arm64.zip
rm -rf packer_${PACKER_VERSION}_linux_arm64.zip
chmod +x /usr/local/bin/packer
/usr/local/bin/packer --version
exit
