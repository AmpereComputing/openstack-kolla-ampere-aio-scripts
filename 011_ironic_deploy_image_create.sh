#!/usr/bin/env bash

IRONIC_CONFIG=/etc/kolla/config/ironic
PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/010_ironic_deploy_image_create.log
exec >> $LOGFILE 2>&1

cd ${IRONIC_CONFIG}

# export ELEMENTS_PATH=/usr/local/share/ironic-python-agent-builder/dib
ironic-python-agent-builder debian
