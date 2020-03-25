#!/usr/bin/env bash
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/002_centos_install_kolla.log

exec >> $LOGFILE 2>&1

# Configure libvirt for kolla
# disable libvirt
#systemctl stop libvirt-bin 
#systemctl disable libvirt-bin

systemctl stop libvirtd.service
systemctl disable libvirtd.service

# Open-Iscsi
systemctl stop open-iscsi.service
systemctl dsiable open-iscsi.service

systemctl stop iscsid.service
systemctl disable iscsid.service

# Change to /opt and get sources
cd /opt
git clone https://opendev.org/openstack/kolla
git clone https://opendev.org/openstack/kolla-ansible

# Install Kolla and Kolla-ansible
pip install -U ansible
pip install ./kolla/
pip install ./kolla-ansible/

# Prep the Kolla configuration directory
mkdir -p /etc/kolla/config

# Copy the base templates
cp -R kolla-ansible/etc/kolla/* /etc/kolla

# Copy the kolla-build.conf to /etc/kolla
cp /usr/local/share/kolla/etc_examples/oslo-config-generator/kolla-build.conf /etc/kolla/

# Get the Working Globals.yml
# wget https://raw.githubusercontent.com/AmpereComputing/openstack-kolla-aio-scripts/master/etc/kolla/globals.yml -O /etc/kolla/globals.yml
cd $PROJECT_DIR
cp etc/kolla/globals.yml.centos /etc/kolla/globals.yml

# Create /etc/kolla/config/global.conf

cat << EOF > /etc/kolla/config/magnum.conf
# Adjust Magnum configuration to allow for fedora-atomic k8s templates
#[trust]
#cluster_user_trust = True
#cloud_provider_enabled = True
EOF

