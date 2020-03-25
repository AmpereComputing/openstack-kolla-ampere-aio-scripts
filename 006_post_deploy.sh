#!/usr/bin/env bash

PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/006_post_deploy.log
exec >> $LOGFILE 2>&1

PROJECT_DIR=`pwd`

# Run Kolla-ansible post-deploy to generate the openrc info
kolla-ansible post-deploy

# Source OpenStack credentials
source /etc/kolla/admin-openrc.sh

# install openstack client
pip install -U openstackclient
# Run the deployment eval
./init-runonce

# Remove the image
rm -rf Fedora-AtomicHost-29-20191001.0.aarch64.qcow2
