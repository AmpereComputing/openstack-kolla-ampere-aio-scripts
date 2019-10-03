#!/usr/bin/env bash

# Update package cache and upgrade packages
apt-get update -y && apt-get upgrade -y

# Install dependencies
apt-get install screen rsync git python-dev libffi-dev gcc libssl-dev python-pip python-selinux python-setuptools python-virtualenv -y
# Change to /opt and get sources
cd /opt
git clone https://opendev.org/openstack/kolla
git clone https://opendev.org/openstack/kolla-ansible

# Install Kolla and Kolla-ansible
pip install ./kolla/
pip install ./kolla-ansible/

# Prep the Kolla configuration directory
mkdir /etc/kolla

# Copy the base templates
cp -R kolla-ansible/etc/kolla/* /etc/kolla

# Copy the kolla-build.conf to /etc/kolla
cp /usr/local/share/kolla/etc_examples/oslo-config-generator/kolla-build.conf /etc/kolla/

# Get the Working Globals.yml
wget https://raw.githubusercontent.com/AmpereComputing/openstack-kolla-aio-scripts/master/etc/kolla/globals.yml -O /etc/kolla/globals.yml

# Build the container imagesa from source
kolla-build -b ubuntu -t source

# Generate passwords for use with kolla-ansible
kolla-genpwd

# Deploy kolla-ansible all-in-one
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one prechecks
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy

# Run Kolla-ansible post-deploy to generate the openrc info
kolla-ansible post-deploy
