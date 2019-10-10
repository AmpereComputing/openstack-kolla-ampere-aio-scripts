#!/usr/bin/env bash

apt-get install unzip -y
cd /usr/local/bin
wget -cv https://releases.hashicorp.com/terraform/0.12.10/terraform_0.12.10_linux_arm.zip
unzip -u terraform_0.12.10_linux_arm.zip
rm -rf terraform_0.12.10_linux_arm.zip
/usr/local/bin/terraform --version
cd /opt
git clone https://github.com/amperecomputing/terraform-openstack-images
cd terraform-openstack-images
terraform init
terraform plan
terraform apply -auto-approve
exit
