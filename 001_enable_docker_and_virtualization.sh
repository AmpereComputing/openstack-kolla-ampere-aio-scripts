#!/usr/bin/env bash
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/001_enable_docker_and_virtualization.log
exec >> $LOGFILE 2>&1

# Update package cache and upgrade packages
apt-get update -y && apt-get upgrade -y

# Install dependencies
apt-get install 

TOOLS="aptitude screen rsync git curl byobu" 
DOCKER="docker.io" 
PYTHON2="python-dev python-pip python-selinux python-setuptools python-virtualenv"
PYTHON3="python3-dev python3-pip python3-selinux python3-setuptools python3-virtualenv"
DEVEL="libffi-dev gcc libssl-dev"
VIRT='bridge-utils cpu-checker libvirt-daemon* qemu-system qemu-efi virtinst virt-manager open-iscsi'

# Switch to Using Python3 by default
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2

echo "Installing tooling"
apt-get install -y $TOOLS
echo "Installing Python Development"

# Switch to Using Python3 by default
echo "Running Update Alternatives"
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
echo "Installing Python & Dev Packages"
apt-get install -y $PYTHON3 $DEVEL
pip3 install -U pip

echo "Installing Docker"
apt-get install -y $DOCKER
docker info
echo "Installing Virtualization"
apt-get install -y $VIRT

echo "Comment out /etc/hosts line that begins with 127.0.1.1"
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
