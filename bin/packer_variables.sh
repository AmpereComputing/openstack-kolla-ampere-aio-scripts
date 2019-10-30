#!/usr/bin/env bash
source /etc/kolla/admin-openrc.sh
OS_SOURCE_IMAGE=`openstack image list | grep 'ubuntu-18.04'| awk '{print $2}'`
OS_NETWORKS_ID=`openstack network list | grep 'demo-net'| awk '{print $2}'`
OS_FLOATING_IP_POOL='public1'

echo $OS_SOURCE_IMAGE
echo $OS_NETWORKS_ID
echo $OS_FLOATING_IP_POOL


