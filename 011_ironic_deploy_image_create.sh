#!/usr/bin/env bash

# Setting ARCH=aarch64 only appears to work when building centos images switching to arm allows for building debian
# ARCH=aarch64
ARCH=arm64
ELEMENTS_PATH=/usr/local/share/ironic-python-agent-builder/dib
IRONIC_CONFIG=/etc/kolla/config/ironic
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/010_ironic_deploy_image_create.log
exec >> $LOGFILE 2>&1

cd ${IRONIC_CONFIG}

#export ARCH=aarch64
#export ELEMENTS_PATH=/usr/local/share/ironic-python-agent-builder/dib

# Currently using ironic-python-agent-builder doesn't seem to work properly for debian
#   ironic-python-agent-builder debian - Worked  when using ARCH=arm64
#   ironic-python-agent-builder centos - Worked when using ARCH=aarch64
#
# However I had success building the bits using the following disk image buildier command
#   disk-image-builder debian -a arm64 -o ironic-python-agent ironic-python-agent-ramdisk

ironic-python-agent-builder debian
