![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# Deploying an Openstack All-in-One deployment on Ampere Aarch64 Servers

## Introduction

Ampere is know for leading the industry with our Arm64 processors optimized for cloud workloads. In a lot of discussions with opensource developers, we get asked for some usescases for all that compute power.  Obviously virtualization and containerization immediately come to mind when thinking about how to take advantage of all those Arm64 cores.  OpenStack is a great workload to test and show the capilbilies of Ampere servers, because it provides a managment API framework for providing different cloud releated services/analogs to Amazon/Azure/GCE that can be deployed within ones own datacenter.  Then once deployed you can utilize devops tooling with the provided OpenStack APIs to quickly deploy virtual machine resources at scale.  The goal of this document is to provide a technical guide to assist in the deployment of an OpenStack All-In-One deployment for servers with Arm64.

While researching the how's and what's to get to a working OpenStack deployment for Aarch64 based platforms I went through different combinations and permutations of the different deployment tools for deploying OpenStack.   The results you will find here were the easiest and fastest way to achieve a working OpenStack which provides basic virtualization functionality.  At the current time, [OpenStack Kolla](https://opendev.org/openstack/kolla), and [OpenStack Kolla-Ansible](https://opendev.org/openstack/kolla-ansible) are the easiest way to deploy an OpenStack AIO on Aarch64 systems.   Additionally [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) for Aarch64 are maintained in upstream continuous integration by the community ensuring a functioning OpenStack deployment for Arm based architectures.

Specifically kolla is used to build containers for the OpenStack services from source.  Kolla-ansible then uses the previously built containers to deploy a containerized OpenStack All-In-One (AIO) on an Ampere server. 


## Requirements
The server is installed with standard Debian version 10.1.0 arm64 and OpenStack 8.1.0 Stein. In this configuration, the administrator can create virtual instances using various preloaded aarch64 operating systems (Debian, Fedora, Fedora-Atomic, Ubuntu, K3OS) through the Horizon web interface or via Terraform.
[OpenStack Kolla](https://opendev.org/openstack/kolla) is used to build containers from source. Kolla-ansible is used to install OpenStack as an All-In-One deployment scenerio.

<script  id="asciicast-276985" src="https://asciinema.org/a/276985.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

* Netboot iso for [Debian Buster 10.1 ARM64](https://gensho.ftp.acc.umu.se/mirror/cdimage/release/10.1.0/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso)

## Installation Steps

The goal of the included scripts are to provide an easy way to replicate an OpenStack AIO deployment using Kolla and Kolla-ansible on AARCH64.
The follow is the basic pattern for deploying using the supplied scripts.

1. Deploy a minimal operating system with ssh access and git installed.
1. Download this repository to the deployment target
1. Make changes to [etc/kolla/globals.yml](etc/kolla/globals.yml) and [init-runonce](init-runonce) for your deployment needs.
1. Run scripts from this repository in numerical order on the target host.

## Prepare for Kolla

Install prerequisite packages and configure docker and kvm virtualization on Debian

Switch to Using Python3 by default

```
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
```

Installing tooling


```
apt-get install -y aptitude screen rsync git curl byobu asciinema tcpdump
```

Installing Python Development packages


```
apt-get install -y python3-dev python3-pip python3-selinux python3-setuptools python3-virtualenv libffi-dev gcc libssl-dev 
```

Upgrade pip
```
pip3 install -U pip
```

Install docker and other virtualiziation tools

```
apt-get install -y docker.io bridge-utils cpu-checker libvirt-daemon* qemu-system qemu-efi virtinst virt-manager open-iscsi

```


Modify /etc/hosts file and comment out the line that begins with 127.0.1.1

```
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts

```


* [001_centos_enable_docker_and_virtualization.sh:](001_enable_docker_and_virtualization.sh)
  * Installs prerequisite packages and configures docker and kvm virtualization on Centos
* [002_install_kolla.sh:](002_install_kolla.sh)
  * Installs Kolla and Kolla-ansible from source on Debian
* [002_centos_install_kolla.sh:](002_install_kolla.sh)
  * Installs Kolla and Kolla-ansible from source on Centos
* [003_build_containers.sh:](003_build_containers.sh)
  * Uses `kolla-build` to build Debian containers from source on the deployment host.
  * Process wrapped in `asciinema` for recording build console output.
* [003_build_containers.sh:](003_centos_build_containers.sh)
  * Uses `kolla-build` to build Centos containers from source on the deployment host.
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
* [010_ironic_deploy_image_tools.sh](010_ironic_deploy_image_tools.sh)
  * Download and install ironic tooling from source
* [011_ironic_deploy_image_create.sh](011_ironic_deploy_image_create.sh)
  * Run ironic-python-agent-builder to create ironic deploy kernel and initrd
* [012_ironic_publish_deploy_image_create_baremetal_flavor.sh](012_ironic_publish_deploy_image_create_baremetal_flavor.sh)
  * Run ironic-python-agent-builder to create ironic deploy kernel and initrd
* [013_ironic_register_node.sh]()
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
