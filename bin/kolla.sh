#!/usr/bin/env bash

PROJECT_DIR=`pwd`

# Update package cache and upgrade packages
apt-get update -y && apt-get upgrade -y

# Install dependencies
apt-get install aptitude docker.io screen rsync git curl python-dev libffi-dev gcc libssl-dev python-pip python-selinux python-setuptools python-virtualenv python-openstackclient bridge-utils cpu-checker "libvirt-daemon*" qemu-system qemu-efi virtinst virt-manager -y

pause
# Configure libvirt for kolla
systemctl stop libvirt-bin 
systemctl disable libvirt-bin
systemctl stop libvirtd
systemctl disable libvirtd

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

# Build the container imagesa from source
kolla-build -b debian -t source

# Generate passwords for use with kolla-ansible
kolla-genpwd

# Deploy kolla-ansible all-in-one
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one prechecks
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy

# Run Kolla-ansible post-deploy to generate the openrc info
kolla-ansible post-deploy

# Source OpenStack credentials
source /etc/kolla/admin-openrc.sh

# Run the deployment eval
./init-runonce

# Remove the image
rm -rf bionic-server-cloudimg-arm64.img
