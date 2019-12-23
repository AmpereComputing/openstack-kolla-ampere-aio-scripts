#!/usr/bin/env bash

TERRAFORM_VERSION='0.12.18'

source /etc/kolla/admin-openrc.sh
apt-get install unzip -y
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_$TERRAFORM_VERSION_linux_arm.zip
unzip -u terraform_$TERRAFORM_VERSION_linux_arm.zip
rm -rf terraform_$TERRAFORM_VERSION_linux_arm.zip
/usr/local/bin/terraform --version
cd /opt
git clone https://github.com/amperecomputing/terraform-openstack-images
cd terraform-openstack-images
terraform init
terraform plan
terraform apply -auto-approve
exit
