#!/usr/bin/env bash


# Uncomment this line to record the output of the build with asciinema
# asciinema rec -q --title="openstack-kolla-ampere-build-containers" -c 'kolla-build -b centos -t source' ./assets/BUILD.json 

# Comment this line if using asciinema above
kolla-build -b centos --base-tag 8 -t source
