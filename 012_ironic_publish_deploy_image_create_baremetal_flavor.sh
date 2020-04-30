#!/usr/bin/env bash

IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_FLAVOR_NAME=baremetal.falcon
IRONIC_DEPLOY_KERNEL=ironic-deploy-kernel
IRONIC_DEPLOY_INITRD=ironic-deploy-initrd
# Actual
#RAM_MB=120000
#CPU=32
#DISK_GB=890
RAM_MB=512
CPU=1
DISK_GB=10


PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/012_ironic_publish_deploy_image_create_baremetal_flavor.log
exec >> $LOGFILE 2>&1

source /etc/kolla/admin-openrc.sh
openstack image create --disk-format aki --container-format aki --public --file ${IRONIC_CONFIG}/ironic-python-agent.kernel ${IRONIC_DEPLOY_KERNEL}
openstack image create --disk-format ari --container-format ari --public --file ${IRONIC_CONFIG}/ironic-python-agent.initramfs ${IRONIC_DEPLOY_INITRD}
openstack flavor create --ram ${RAM_MB} --disk ${DISK_GB} --vcpus ${CPU} ${IRONIC_FLAVOR_NAME} --property resources:VCPU=0 --property resources:MEMORY_MB=0 --property resources:DISK_GB=0
