#!/usr/bin/env bash
IRONIC_CONFIG=/etc/kolla/config/ironic
IRONIC_API_VERSION=1.11
OS_BAREMETAL_API_VERSION=1.11
PROJECT_DIR=`pwd`

source /etc/kolla/admin-openrc.sh


NODE_UUID=`openstack baremetal node list | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
PORT_UUID=`openstack baremetal port list | awk '{print $2}' | tr '\012' ' ' | awk '{print $2}'`
echo "NODE UUID = "$NODE_UUID
echo "PORT UUID = "$PORT_UUID
openstack baremetal node delete ${NODE_UUID}
openstack baremetal port delete ${PORT_UUID}
