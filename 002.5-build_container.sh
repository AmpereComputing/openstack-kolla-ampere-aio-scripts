#!/usr/bin/env bash
asciinema rec -q --title="openstack-kolla-ampere-build-containers" -c 'kolla-build -b debian -t source' ./assets/BUILD.json 
