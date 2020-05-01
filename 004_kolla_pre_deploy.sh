#!/usr/bin/env bash
PROJECT_DIR=`pwd`
LOGFILE="${PROJECT_DIR}/004_kolla_pre_deploy.log"
exec >> $LOGFILE 2>&1

# Generate passwords for use with kolla-ansible
kolla-genpwd

# Deploy kolla-ansible all-in-one
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
# need to install this to get it to work properly.
# apt-get install -y python-backports.ssl-match-hostname -y
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one prechecks

