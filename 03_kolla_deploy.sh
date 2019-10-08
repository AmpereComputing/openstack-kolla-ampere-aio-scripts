#!/usr/bin/env bash

PROJECT_DIR=`pwd`

# Generate passwords for use with kolla-ansible
kolla-genpwd

# Deploy kolla-ansible all-in-one
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
# need to install this to get it to work properly.
# apt-get install -y python-backports.ssl-match-hostname -y
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
