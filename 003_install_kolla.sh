#!/usr/bin/env bash
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/003_install_kolla.log

exec >> $LOGFILE 2>&1

# Configure libvirt for kolla
# disable libvirt
systemctl stop libvirt-bin 
systemctl disable libvirt-bin
systemctl stop libvirtd
systemctl disable libvirtd

# Open-Iscsi
systemctl stop open-iscsi.service
systemctl dsiable open-iscsi.service
systemctl stop iscsid.service
systemctl disable iscsid.service


# Disable Apparmor libvirt profile
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd


# Change to /opt and get sources
cd /opt
git clone https://opendev.org/openstack/kolla
git clone https://opendev.org/openstack/kolla-ansible

# Install Kolla and Kolla-ansible
pip install -U ansible
pip install ./kolla/
pip install ./kolla-ansible/

# Prep the Kolla configuration directory
mkdir /etc/kolla

# Copy the base templates
cp -R kolla-ansible/etc/kolla/* /etc/kolla

# Copy the kolla-build.conf to /etc/kolla
cp /usr/local/share/kolla/etc_examples/oslo-config-generator/kolla-build.conf /etc/kolla/

# Get the Working Globals.yml
# wget https://raw.githubusercontent.com/AmpereComputing/openstack-kolla-aio-scripts/master/etc/kolla/globals.yml -O /etc/kolla/globals.yml
cd $PROJECT_DIR
cp etc/kolla/globals.yml /etc/kolla/globals.yml
