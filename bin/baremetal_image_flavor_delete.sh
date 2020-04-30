#!/usr/bin/env bash
IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_API_VERSION=1.11
OS_BAREMETAL_API_VERSION=1.11
PROJECT_DIR=`pwd`

source /etc/kolla/admin-openrc.sh

openstack image delete ironic-deploy-kernel
openstack image delete ironic-deploy-initrd
openstack flavor delete baremetal.falcon
