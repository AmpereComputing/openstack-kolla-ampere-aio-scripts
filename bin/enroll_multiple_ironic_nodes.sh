#!/usr/bin/env bash

PROJECT_DIR=`pwd`

# Ipmi Settings
IPMI_USERNAME=ADMIN
IPMI_PASSWD=ADMIN

# Declare all IPMI Hosts
declare -a ironic_hosts=(
# Ironic Host, IPMI_ADDRESS, PXE_INTERACE_MAC
falcon04,'10.76.116.164','b8:59:9f:09:15:4b'
falcon05,'10.76.116.165','b8:59:9f:09:15:4b'
falcon06,'10.76.116.166','b8:59:9f:09:15:4b'
)

OS_BAREMETAL_API_VERSION=1.11
IRONIC_API_VERSION=1.11
IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_FLAVOR_NAME=baremetal.falcon
IRONIC_API_VERSION=1.11

#source /etc/kolla/admin-openrc.sh
#IRONIC_DEPLOY_KERNEL=`openstack image list | grep ${IRONIC_DEPLOY_KERNEL} | awk '{print $2}'`
#IRONIC_DEPLOY_INITRD=`openstack image list | grep ${IRONIC_DEPLOY_INITRD} | awk '{print $2}'`

echo ${IRONIC_DEPLOY_KERNEL}
echo ${IRONIC_DEPLOY_INITRD}

## now loop through the above array
for i in "${ironic_hosts[@]}";
do
ironic_host_name=`echo $i |awk -F "," '{print $1}'`
ironic_ipmi_address=`echo $i |awk -F "," '{print $2}'`
ironic_pxe_interface_mac=`echo $i |awk -F "," '{print $3}'`

echo "ironic ipmi interface: " $ironic_ipmi_address
echo "ironic pxe interface mac address: " $ironic_pxe_interface_mac

#openstack flavor show ${IRONIC_FLAVOR_NAME} -f value -c properties
openstack baremetal node create \
	--driver ipmi \
        --name baremetal-${ironic_host_name}
	--driver-info ipmi_username=${IPMI_USERNAME} \
	--driver-info ipmi_password=${IPMI_PASSWD} \
	--driver-info ipmi_address=${ironic_ipmi_address} \
	--resource-class baremetal-resource-class \
	--property cpus=1 \
	--property memory_mb=512 \
	--property local_gb=1 \
	--property cpu_arch=arm64 \
	--property capabilities='boot_mode:uefi' \
	--driver-info deploy_kernel=${IRONIC_DEPLOY_KERNEL} \
	--driver-info deploy_ramdisk=${IRONIC_DEPLOY_INITRD}
	--property cpu_arch=arm64 \
	--deploy-interface direct \
	--raid-interface agent \

NODE_UUID=`openstack baremetal node list | grep ${ironic_host_name} | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
echo "*** IRONIC NODE UUID = " ${NODE_UUID} " ***"

echo "*** IRONIC Baremetal node show" ${NODE_UUID} " ***"
openstack baremetal node show ${NODE_UUID}

echo "*** IRONIC Baremetal node console enable" ${NODE_UUID} " ***"
openstack baremetal node console enable ${NODE_UUID}

echo "*** IRONIC Creating baremetal port added for node " ${NODE_UUID} " ***"
openstack baremetal port create ${ironic_pxe_interface_mac} --node ${NODE_UUID}

echo "*** IRONIC baremetal node validate " ${NODE_UUID} " ***"
openstack baremetal node validate ${NODE_UUID}

echo "*** IRONIC baremetal node manage " ${NODE_UUID} " ***"
openstack baremetal node manage ${NODE_UUID}

echo "*** IRONIC baremetal node inspect " ${NODE_UUID} " ***"
openstack baremetal node inspect ${NODE_UUID}

echo "*** IRONIC Baremetal node show" ${NODE_UUID} " ***"
openstack baremetal node show ${NODE_UUID}

echo "*** IRONIC Baremetal node provide" ${NODE_UUID} " ***"
openstack baremetal node provide ${NODE_UUID}

echo "*** IRONIC Baremetal node show" ${NODE_UUID} " ***"
openstack baremetal node show ${NODE_UUID}

# Show Hypervisor Stats
echo "*** OpenStack Hypervisor stats show ***"
openstack hypervisor stats show

echo "*** OpenStack Hypervisor show " ${NODE_UUID} " ***"
openstack hypervisor show ${NODE_UUID}

done
