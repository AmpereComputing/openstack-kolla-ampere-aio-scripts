#!/usr/bin/env bash

IRONIC_CONFIG=/etc/kolla/config/ironic
#ELEMENTS_PATH=/usr/local/share/ironic-python-agent-builder/dib
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/010_ironic_deploy_image_tools.log
exec >> $LOGFILE 2>&1

# ensure tooling is present
apt-get update -y && apt-get install ipmitool qemu-utils kpartx hdparm  util-linux squashfs-tools genisoimage debootstrap qemu-block-extra uuid-runtime shellinabox socat -y 

# Change to /opt and download ironic tooling form src
cd /opt

git clone https://opendev.org/openstack/diskimage-builder
git clone https://opendev.org/openstack/ironic-python-agent
git clone https://opendev.org/openstack/ironic-python-agent-builder

# Install 
pip install -U ./diskimage-builder
pip install -U ./ironic-python-agent
pip install -U ./ironic-python-agent-builder

# Create the ironic config
mkdir -p ${IRONIC_CONFIG}
