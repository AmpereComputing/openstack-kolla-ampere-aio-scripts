![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# openstack-kolla-ampere-aio-scripts

Scripts and information for reproducing an OpenStack All-In-One deployment on Ampere eMAG systems using OpenStack Kolla and Kolla-Ansible.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Description

This repository contains script & file assets to build from source & deploy a containerized OpenStack All-In-One (AIO) on an Ampere eMAG server. The server is installed with standard Debian version 10.1.0 arm64 and OpenStack 8.1.0 Stein. In this configuration, the administrator can create virtual instances using various preloaded aarch64 operating systems (Debian, Fedora, Fedora-Atomic, Ubuntu, K3OS) through the Horizon web interface or via Terraform.
[OpenStack Kolla](https://opendev.org/openstack/kolla) is used to build containers from source. Kolla-ansible is used to install OpenStack as an All-In-One deployment scenerio.

<script  id="asciicast-276985" src="https://asciinema.org/a/276985.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

## Operating System Requirements

* Netboot iso for [Debian Buster 10.1 ARM64](https://gensho.ftp.acc.umu.se/mirror/cdimage/release/10.1.0/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso)

## Installation Overview

The goal of the included scripts are to provide an easy way to replicate an OpenStack AIO deployment using Kolla and Kolla-ansible on AARCH64.
The follow is the basic pattern for deploying using the supplied scripts.

1. Deploy a minimal operating system with ssh access and git installed.
1. Download this repository to the deployment target
1. Make changes to [etc/kolla/globals.yml](etc/kolla/globals.yml) and [init-runonce](init-runonce) for your deployment needs.
1. Run scripts from this repository in numerical order on the target host.

### Script Assets

* [001_enable_docker_and_virtualization.sh:](001_enable_docker_and_virtualization.sh)
  * Installs prerequisite packages and configures docker and kvm virtualization
* [002_install_kolla.sh:](002_install_kolla.sh)
  * Installs Kolla and Kolla-ansible from source
* [003_build_containers.sh:](003_build_containers.sh)
  * Uses `kolla-build` to build Debian containers from source on the deployment host.
  * Process wrapped in `asciinema` for recording build console output.
* [004_kolla_pre_deploy.sh:](004_kolla_pre_deploy.sh)
  * Runs kolla-ansible generate-certificates, bootstrap-servers and prechecks before deploy
* [005_kolla_deploy.sh:](005_kolla_deploy.sh)
  * Runs kolla-ansible deploy wrapped in Acsiinema for recording deploy console output.
* [006_post_deploy.sh:](006_post_deploy.sh)
  * Runs kolla-ansible post-deploy to genterate credentials in /etc/kolla/admin-openrc.sh
  * Executes init-runonce with information specific to our network deployment in order to prepopulate project, network, subnet, image, keys for admin
* [007_terraform.sh:](007_terraform.sh)
  * Installs [Terraform](https://terraform.io) to use to automate interaction with the cloud resources available on the deployed OpenStack AIO
  * Downloads source for [terraform-openstack-images](https://github.com/amperecomputing/terraform-openstack-images)
  * Runs terraform to deploy a base set of AARCH64 QCOW2 images onto the OpenStack AIO
* [008_packer.sh:](008_packer.sh)
  * Downloads and installs [Packer](https://packer.io)
* [009_k3OS_packer_image.sh:](009_k3OS_packer_image.sh)
  * Downloads source with OpenStack packer template for [k3OS](https://github.com/ppouliot/k3os)
  * Builds a k3OS image using packer.
* [init-runonce:](init-runonce) Modified init-runonce with values that will work on network.


## Building Kolla Images

Container images can be rebuilt at any time through the use of the `kolla-build` command.
Kolla supports different operating system options for the Docker containers.
During the process of building this both Ubuntu and Debian were attempted.
Currently Debian was fully funcitonal where at the time this was created Ubuntu 18.04 was unable to sucessfully deploy a virtual machine with Libvirt running containerized.
The Debian functionality including AARCH64 support was contributed by Linaro, whom currently still actively contributes to the maintaince of the AARCH64 integration.

###  Paste Logs from Ubuntu 18.04 Libvirt failures

For those interested the following information was gathered during the troubleshooting of the issues with Livbvirtd containerized in this deployment

  * [libvirtd.log](http://paste.openstack.org/show/781097/)
  * [nova-compute.log](http://paste.openstack.org/show/781098/)

## Configuration 

Configuration is done via the included globals.yml file.
The included Kolla globals.yml configuration file used to produce an OpenStack All-In-One.
You will need to edit this file and change necessary information prior to the deploy process.

* [etc/kolla/globals.yml](etc/kolla/globals.yml)

The modifications that were made to the global.yml to produce a working AIO during this process were:

```
kolla_base_distro: "debian"
openstack_release: "8.1.0"
kolla_internal_vip_address: "10.1.1.88"
network_interface: "enp1s0"
neutron_external_interface: "enx00051bb122ed"
nova_compute_virt_type: "kvm"
enable_haproxy: "no"
```

** Please note that the neutron_external_interface is actually a USB nic that was used to provide a second interface on the working system.   The interfaces and addresses  must be changed to the appropriate working and active network interfaces for the deployment to be successful. **

Additionally `init-runonce` is executed during the script processes.  Modifications will be necessary to ensure a proper functioning OpenStack deployment after installation.

* [init-runonce](init-runonce)

Theses changes represent the Network information of the subnet of the active interface with a range of IP addresses that can be used for assigning `floating-ips` to the virtual machine instances.  The changes used in the this example are the following:

```
EXT_NET_CIDR='10.1.1.0/24'
EXT_NET_RANGE='start=10.1.1.210,end=10.1.1.240'
EXT_NET_GATEWAY='10.1.1.1'
```
## References

The following information assets were acquired during the research process of this endeavour.

* [Kolla Image Building](https://docs.openstack.org/kolla/latest/admin/image-building.html)
* [Kolla Ansible AIO Quickstart](https://docs.openstack.org/openstack-ansible/latest/user/aio/quickstart.html)
* [Install and configure OpenStack Ocata with Kolla as a Standalone](https://blog.inkubate.io/install-and-configure-openstack-ocata-with-kolla-as-a-standalone)
* [OpenStack, Ansible, and Kolla on Ubuntu 1604](https://elatov.github.io/2018/01/openstack-ansible-and-kolla-on-ubuntu-1604/)
* [Build a versatile OpenStack Lab using Kolla](https://www.linuxjournal.com/content/build-versatile-openstack-lab-kolla)
* [Migrating a running OpenStack to containerisation with Kolla](https://www.stackhpc.com/migrating-to-kolla.html)
* [OpenStack Kolla All-In-One](https://www.openstackfaq.com/openstack-kolla-all-in-one/)
* [Experience using Kolla-ansible to upgrade OpenStack from Ocata to Queens](https://blog.zhaw.ch/icclab/experience-using-kolla-ansible-to-upgrade-openstack-from-ocata-to-queens/)
* [How to deploy and configure a bare metal controller using OpenStack ironic part 4](https://software.intel.com/en-us/blogs/2017/04/19/how-to-configure-and-deploy-a-bare-metal-controller-using-openstack-ironic-part-4)
* [OpenStack-Kolla](https://shreddedbacon.com/post/openstack-kolla/)
* [OpenStack Tacker and Service function chaining sfc with Kolla](https://egonzalez.org/docs/build/html/2017-08-28-openstack-tacker-and-service-function-chaining-sfc-with-kolla.html)
* [OpenStack kolla deployment from RDO packages](https://egonzalez.org/docs/build/html/2016-04-24-openstack-kolla-deployment-from-rdo-packages.html)
* [Deploy OpenStack designate with kolla-ansible](https://egonzalez.org/docs/build/html/2017-02-22-deploy-openstack-designate-with-kolla-ansible.html)
* [Testing containerized OpenStack services with kolla](http://jaormx.github.io/2017/testing-containerized-openstack-services-with-kolla/)
* [Kolla Configuration](https://storage.gra1.cloud.ovh.net/v1/AUTH_dcaab5e32b234d56b626f72581e3644c/logs_46/676646/1/gate/openstack-tox-docs/a912ea4/html/configuration/kolla.html)
* [How to Build an OpenStack Lab using Kolla-Ansible](https://www.packetflow.co.uk/openstack-installation-via-kolla-anisble/)
* [Deploying OpenStack Kolla Ocata](https://jamesbenson.weebly.com/blog/deploying-openstack-kolla-ocata)
* [Deploying OpenStack Part 2 - Post Deployment](https://jamesbenson.weebly.com/blog/deploying-openstack-part-2-post-deployment)
* [Ansible and kolla a on Ubuntu](https://elatov.github.io/2018/01/openstack-ansible-and-kolla-on-ubuntu-1604/)
