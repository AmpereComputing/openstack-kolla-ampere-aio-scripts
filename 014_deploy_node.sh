#!/usr/bin/env bash
PROJECT_DIR=`pwd`
LOGFILE=${PROJECT_DIR}/013_ironic_enroll_node.log
exec >> ${LOGFILE} 2>&1

source /etc/kolla/admin-openrc.sh
IPMI_USERNAME=ADMIN
IPMI_PASSWD=ADMIN
IPMI_ADDRESS='10.76.116.169'
PXE_INTERFACE_MAC='b8:59:9f:1a:81:23'
IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_FLAVOR_NAME=baremetal.falcon
IRONIC_API_VERSION=1.11
OS_BAREMETAL_API_VERSION=1.11
NODE_UUID=`openstack baremetal node list | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
IRONIC_DEPLOY_KERNEL=`openstack image list | grep ${IRONIC_DEPLOY_KERNEL} | awk '{print $2}'`
IRONIC_DEPLOY_INITRD=`openstack image list | grep ${IRONIC_DEPLOY_INITRD} | awk '{print $2}'`

echo ${IRONIC_DEPLOY_KERNEL}
echo ${IRONIC_DEPLOY_INITRD}

#/usr/bin/ipmitool -H "${IPMI_ADDRESS}" -U"${IPMI_USER}" -P"${IPMI_PASSWD}" -Ilanplus chassis status

openstack flavor list
openstack image list
openstack baremetal driver list
openstack flavor show ${IRONIC_FLAVOR_NAME} -f value -c properties

NODE_UUID=`openstack baremetal node list | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
echo "NODE UUID = "$NODE_UUID
openstack baremetal node show ${NODE_UUID}
openstack hypervisor stats show

openstack server create --image debian-10-openstack-arm64-qcow2 --flavor baremetal.falcon --key-name mykey --network public1 falcon-test-01
