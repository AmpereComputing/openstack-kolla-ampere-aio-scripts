#!/usr/bin/env bash

PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/centos_kolla.log
exec >> $LOGFILE 2>&1

TOOLS="screen rsync git curl"
DOCKER="docker-ce docker-ce-cli containerd.io"
PYTHON3="python-devel libselinux-python platform-python-pip"
DEVEL="libffi-devel gcc openssl-devel"
VIRT="qemu-kvm qemu-img libvirt virt-install libvirt-client iscsi-initiator-utils"

# Add Docker package repositories
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

# Update package cache and upgrade packages
dnf check-update -y && dnf update -y

echo "Installing tooling"
dnf install -y $TOOLS

echo "Installing Pythong Development"
dnf install -y $PYTHON3 $DEVEL

echo "Installing and Testing Docker"
dnf install -y --nobest $DOCKER
docker info

echo "Installing Virtualization"
dnf install -y $VIRT

echo "Comment out /etc/hosts line that begins with 127.0.1.1"
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
