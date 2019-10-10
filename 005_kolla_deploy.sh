#!/usr/bin/env bash
asciinema rec -q --title="openstack-kolla-ampere-aio-deploy" -c 'kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy' ./assets/DEPLOY.json 
