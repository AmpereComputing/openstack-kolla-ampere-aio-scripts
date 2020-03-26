#!/usr/bin/env bash

# Configure libvirt for kolla
# disable libvirt
#systemctl stop libvirt-bin
#systemctl disable libvirt-bin

# Stop Libvirtd
systemctl stop libvirtd.service
systemctl disable libvirtd.service

# Stop Libvirt-guests
systemctl stop libvirt-guests.service
systemctl disable libvirt-guests.service

# Stop virtlockd
systemctl stop virtlockd.service
systemctl disable virtlockd.service

# Stop virtlockd-admin
systemctl stop virtlockd-admin.service
systemctl disable virtlockd-admin.service
