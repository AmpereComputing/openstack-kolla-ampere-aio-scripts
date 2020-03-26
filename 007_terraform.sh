#!/usr/bin/env bash

PROJECT_DIR=`pwd`
LOGFILE=$PROJECT_DIR/007_terraform.log
exec >> $LOGFILE 2>&1

source ${PROJECT_DIR}/ENVIRONMENT
echo $TERRAFORM_VERSION

source /etc/kolla/admin-openrc.sh
apt-get install unzip -y
rm -rf /usr/local/bin/terraform
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm.zip
unzip -u terraform_${TERRAFORM_VERSION}_linux_arm.zip
rm -rf terraform_${TERRAFORM_VERSION}_linux_arm.zip
/usr/local/bin/terraform --version
cd /opt
git clone https://github.com/amperecomputing/terraform-openstack-images
cd terraform-openstack-images
terraform init
terraform plan
terraform apply -auto-approve
exit
