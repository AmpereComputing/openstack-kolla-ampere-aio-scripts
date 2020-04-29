#!/usr/bin/env bash

IRONIC_CONFIG=/etc/kolla/config/ironic
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/012_ironic_publish_deploy_image_create_baremetal_flavor.log
exec >> $LOGFILE 2>&1

source /etc/kolla/admin-openrc.sh

openstack image create --disk-format aki --container-format aki --public --file ${IRONIC_CONFIG}/ironic-python-agent.kernel deploy-vmlinuz
openstack image create --disk-format ari --container-format ari --public --file ${IRONIC_CONFIG}/ironic-python-agent.initramfs deploy-initrd

openstack flavor create --ram 1044 --disk 1 --vcpus 1 falcon-baremetal-flavor
openstack flavor set falcon-baremetal-flavor --property resources:CUSTOM_BAREMETAL_RESOURCE_CLASS=1 resources:resources:VCPU=0 resources:resources:MEMORY_MB=0 resources:resources:DISK_GB=0
