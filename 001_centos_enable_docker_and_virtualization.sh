#!/usr/bin/env bash

PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/centos_kolla.log
exec >> $LOGFILE 2>&1

TOOLS="screen rsync git curl"
DOCKER="docker-ce docker-ce-cli containerd.io"
PYTHON3="platform-python-devel python3-libselinux python3 python3-pip python3-setuptools python3-virtualenv"
DEVEL="libffi-devel gcc openssl-devel"
VIRT="qemu-kvm qemu-img libvirt virt-install libvirt-client iscsi-initiator-utils libvirt-daemon-kvm"

# Add Docker and EPEL-Release package repositories
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y epel-release

# Update package cache and upgrade packages
dnf check-update -y && dnf update -y

echo "Installing tooling"
dnf install -y $TOOLS

echo "Installing Python Development"
dnf install -y $PYTHON3 $DEVEL
alternatives --set python /usr/bin/python3
alternatives --set pip /usr/bin/pip3

echo "Installing Enabling and Testing Docker"
dnf install -y --nobest $DOCKER
systemctl enable docker
systemctl start docker
docker info

echo "Installing Virtualization"
dnf install -y $VIRT

echo "Comment out /etc/hosts line that begins with 127.0.1.1"
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
