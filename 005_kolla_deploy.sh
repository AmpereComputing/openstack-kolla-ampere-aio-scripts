#!/usr/bin/env bash

# Uncomment this line to record build with asciinema
# asciinema rec -q --title="openstack-kolla-ampere-aio-deploy" -c 'kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy' ./assets/DEPLOY.json 


# Comment this line if using asciinema above
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy
