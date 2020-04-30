#!/usr/bin/env bash
IPMI_USERNAME=ADMIN
IPMI_PASSWD=ADMIN
IPMI_ADDRESS='10.76.116.169'
PXE_INTERFACE_MAC='b8:59:9f:1a:81:23'

IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_FLAVOR_NAME=baremetal.falcon
IRONIC_API_VERSION=1.11
IRONIC_DEPLOY_KERNEL='ironic-deploy-kernel'
IRONIC_DEPLOY_INITRD='ironic-deploy-initrd'
OS_BAREMETAL_API_VERSION=1.11
PROJECT_DIR=`pwd`
LOGFILE=${PROJECT_DIR}/013_ironic_enroll_node.log
exec >> ${LOGFILE} 2>&1

source /etc/kolla/admin-openrc.sh
IRONIC_DEPLOY_KERNEL=`openstack image list | grep ${IRONIC_DEPLOY_KERNEL} | awk '{print $2}'`
IRONIC_DEPLOY_INITRD=`openstack image list | grep ${IRONIC_DEPLOY_INITRD} | awk '{print $2}'`

echo ${IRONIC_DEPLOY_KERNEL}
echo ${IRONIC_DEPLOY_INITRD}

#/usr/bin/ipmitool -H "${IPMI_ADDRESS}" -U"${IPMI_USER}" -P"${IPMI_PASSWD}" -Ilanplus chassis status

openstack flavor list
openstack image list
openstack baremetal driver list
openstack flavor show ${IRONIC_FLAVOR_NAME} -f value -c properties
openstack baremetal node create \
	--driver ipmi \
	--name falcon-01 \
	--driver-info ipmi_username=${IPMI_USERNAME} \
	--driver-info ipmi_password=${IPMI_PASSWD} \
	--driver-info ipmi_address=${IPMI_ADDRESS} \
	--resource-class baremetal-resource-class \
	--driver-info deploy_kernel=${IRONIC_DEPLOY_KERNEL} \
	--driver-info deploy_ramdisk=${IRONIC_DEPLOY_INITRD}
#	--property cpus=1 \
#	--property memory_mb=512 \
#	--property cpu_arch=arm64 \
#	--property local_gb=1 \
#	--deploy-interface direct \
#	--raid-interface agent \

NODE_UUID=`openstack baremetal node list | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
echo "NODE UUID = "$NODE_UUID
openstack baremetal node show ${NODE_UUID}
openstack baremetal port create ${PXE_INTERFACE_MAC} --node ${NODE_UUID}
openstack baremetal node validate ${NODE_UUID}
echo "Node Manage & Inspect"
openstack baremetal node manage ${NODE_UUID}
openstack baremetal node inspect ${NODE_UUID}
openstack baremetal node show ${NODE_UUID}
echo "Node Provide"
openstack baremetal node provide ${NODE_UUID}
openstack baremetal node show ${NODE_UUID}
