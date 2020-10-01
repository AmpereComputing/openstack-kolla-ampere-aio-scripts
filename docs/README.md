![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# Deploying an Openstack All-in-One deployment on Ampere Aarch64 Servers

## Introduction

Ampere is known for leading the industry with our Arm64 processors optimized for cloud workloads. In many discussions with opensource developers, we get asked for some usescases for all (can you explain all? ) that compute power.  Obviously virtualization and containerization immediately come to mind when we think about how to take advantage of all those Arm64 cores.  OpenStack is a great workload to test and show the capabilities of Ampere servers. This is  because it provides a managment API framework for providing different cloud releated services/analogs to Amazon/Azure/GCE that can be deployed within ones own datacenter.  Once  deployed, one can utilize devops tooling with the provided OpenStack APIs to quickly deploy virtual machine resources at scale.  The goal of this post is to provide a technical guide to assist in the deployment of an OpenStack All-In-One deployment for servers with Arm64 processors.

While researching the best and efficient way to get to a working OpenStack deployment for Arm64 based platforms, I went through different combinations and permutations of the different deployment tools for deploying OpenStack. The steps here are the easiest and fastest to achieve a working OpenStack Cloud which provides basic virtualization functionality. Currently, [OpenStack Kolla](https://opendev.org/openstack/kolla), and [OpenStack Kolla-Ansible](https://opendev.org/openstack/kolla-ansible) are the only ways to deploy an OpenStack AIO on Arm64 systems.  OpenStack-Ansible was attempted but wasn't successful due to lack of complete multiplatform packaging and hard coded requirements for x86 systems. Another reason to use [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) for Arm64 is that the community maintains these projects in an upstream continuous integration ensuring a functioning OpenStack deployment for Arm based architectures.

## Kolla/Kolla-Ansible Primer

A basic understanding of the parts comes handy for better understanding of the deployment process. [Kolla](https://opendev.org/openstack/kolla) is used to build containers for the OpenStack services from source.  [kolla-ansible](https://opendev.org/openstack/kolla-ansible) then uses the previously built containers to deploy a containerized OpenStack All-In-One (AIO) on the Ampere server. At a high level, [kolla-ansible](https://opendev.org/openstack/kolla-ansible) is essentially a tailored deployment of ansible specifically for installing and managing an OpenStack deployment lifecycle.

## Requirements

As anyone who has attempted to install and deploy OpenStack knows, there are supported operating systems, hardware patforms, and components that can be mixed and matched in multiple combinations and permutations. However for the purposes of this, we are going to deploy the system and OpenStack services necessary to allow us to deploy Arm64 virtual machines on a single server with the basics for a good user experience. ( Can you please break the last sentence, it isn't clear). 

### Operating System

Currently and empiricially, [Debian](https://debian.org) is the best choice for base OS platform for running the cloud and for using kolla-ansible with Arm64 platforms.   Given that RedHat and CentOS recently released "Offical" Arm64 based distributions, there may be better experiences with other platforms in the future.(This sentence is confusing!)

The server used for the writing of this was installed with standard Debian version 10.x for Arm64.  Debian releases 10.1-10.4 have been tried with no perceivable difference between iterations when used in this context. The OS is installed in a minimal configuration, only including an ssh server as the additional software selection.

* Netboot iso for [Debian Buster 10.1 ARM64](https://gensho.ftp.acc.umu.se/mirror/cdimage/release/10.1.0/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso)

## Host configuration and Software Installation
After you have functional [Debian](https://debian.org) deployment,  log into the new installation as the "root" user.  The following steps assume that you are using the "root" user account throughout the deployment process and not running the commands via sudo.

### Prepare /etc/hosts

Modify /etc/hosts file and comment out or remove the line that begins with 127.0.1.1. Otherwise, this causes issues with the kolla-ansible deployment process and the ability for containers to resolve names back to the host. Removing it ensures a smooth run of kolla-ansible.  The following sed line will comment out any offending line.

```
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts

```

### Preparing the Python stack for Kolla and Kolla-ansible

[Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) are both Python based projects.  Therefore, our first step after installation is to prepare the python software stack and install any additional python dependencies.  To keep things on a more modern track, we will first switch to using Python3 by default on the base Debian platform by running the following commands.

```
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
```

Next install the required python development packages from default Debian package repositories.

```
apt-get install -y python3-dev python3-pip python3-selinux python3-setuptools python3-virtualenv libffi-dev gcc libssl-dev 
```

When using Kolla and Kolla-ansible, it is best to use the lastest version of pip, python's package management utility.  We will use pip to upgrade pip before installing any additional python from package or from source.

```
pip3 install -U pip
```

### Virtualization, Docker and Additional software.

Once the changes to python stack have been made, the next step in the process is to deploy additional software requirements from the debian package mirrors.  Again no changes to the Apt repository configuration were necessary.(what is the Apt repository, not clear to me)

Installing some useful tooling to aid during debugging, troubleshooting or collecting output, is always useful.  These packages may not be mandatory, but are useful in general.

```
apt-get install -y aptitude screen rsync git curl byobu asciinema tcpdump
```

We need both container engine and virtualization enabled on the host. Next install docker and other virtualiziation tools from Debian packaging.

```
apt-get install -y docker.io bridge-utils cpu-checker libvirt-daemon* qemu-system qemu-efi virtinst virt-manager open-iscsi

```

### Disable local services.

#### Libvirt

In the previous steps, we essentially installed the software necessary to configure hypervisor functionality on the host platform.   However because all the components of the OpenStack [kolla-ansible](https://opendev.org/openstack/kolla-ansible) deployment are containerized, the packages essentially are used to layout the filesystem structure that will map back into some of the containers providing functionality.

Configure libvirt services for kolla by disabling all libvirt services. (what are libvirt services? Are these the packages used to layout the filesystem structure ..... It wasn't clear to me)

```
systemctl stop libvirtd.service
systemctl disable libvirtd.service
```

Stop and disable the Libvirt-guests service.

```
systemctl stop libvirt-guests.service
systemctl disable libvirt-guests.service
```

Stop virtlockd and virtlockd-admin

```
systemctl stop virtlockd.service
systemctl disable virtlockd.service
systemctl stop virtlockd-admin.service
systemctl disable virtlockd-admin.service
```

#### Open-iscsi

Iscsi services are used when running cinder in order to provide block storage services.  Although we may not be using them yet, we will install and stop all open-iscsi services to be prepared for when or if we want to try cinder later.

```
systemctl stop open-iscsi.service
systemctl disable open-iscsi.service
systemctl stop iscsid.service
systemctl disable iscsid.service
```

#### Disable Apparmor libvirt profile

It is necessary to disable the default Apparmor profile for libvirt in order for the containerized libvirt to function properly.

```
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
```

### Install Kolla and Kolla-ansible from source on Debian

Change to /usr/local/src and get sources

```
cd /usr/local/src
git clone https://opendev.org/openstack/kolla
git clone https://opendev.org/openstack/kolla-ansible
```

Install ansible from pip packages.  Currently ansible has major changes when moving from version 2.9.x to 2.10.x.   At this time Kolla-ansible is not compatible with the newere 2.10.x ansible version and only supports ansible 2.9.x.

```
pip install -U 'ansible<2.9'
```

Install Kolla and Kolla-ansible

```
pip install ./kolla/
pip install ./kolla-ansible/
```

Prep the Kolla configuration directory

```
mkdir -p /etc/kolla/config
```

Copy the base globals.yml and passwords.yml


```
cp /usr/local/share/kolla-ansible/etc_examples/kolla/globals.yml /etc/kolla/globals.yml
cp /usr/local/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla/passwords.yml
```

Copy the kolla-build.conf to /etc/kolla

```
cp /usr/local/share/kolla/etc_examples/oslo-config-generator/kolla-build.conf /etc/kolla/
```


### Using Kolla to build container images

The key distinction between "kolla" and "kolla-ansile" is that kolla provides the tooling to build container images for openstack services from package or source on multiple linux platforms.  Kolla-ansible provides the tooling for deploying the images built with Kolla.  As such container images can be built and rebuilt at any time through the use of the `kolla-build` command.

As mentioned Kolla supports different operating system options for the Docker containers used when building OpenStack containers..
During the process of building this, both Ubuntu and Debian were attempted. Debian was fully funcitonal but Ubuntu 18.04 was unable to sucessfully deploy a virtual machine with Libvirt running containerized (Sounds incomplete).  Obviously this may change over time.

The Debian functionality including Arm64 support was contributed by Linaro, who currently still actively contributes to the maintenance and continuous integration of Arm64.

Building container images using kolla will take some time, as all OpenStack containers images need to be  built. Customization of the container images during build are outside the scope of this document. Please refer to the upstream Kolla documentation for more information.

To build contantainer images using Debian as the base operating system and using OpenStack source, run the following cmd.

```
kolla-build -b debian -t source
```

### Kolla-Ansible Configuration 

Kolla-ansible configuration is done via the '/etc/kolla/globals.yml' file.   The file contains options for tuning which OpenStack features and services that are enabled during the deployment.

The included Kolla globals.yml configuration file is used to produce an OpenStack All-In-One.
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


## Running Kolla-ansible

### Kolla-Ansible Pre Deployment

Generate passwords for use with kolla-ansible

```
kolla-genpwd
```

Generate certificates for the deployment.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
```

Bootstrap servers with kolla-ansible requirements

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
```

Run prechecks to validate everything prior to running kolla-ansible deploy.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one prechecks
```

Deploy OpenStack.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy
```

### Configuring OpenStack for first use
Once the openstack services are deployed you will need to do some basic configuration to make the cloud usable. You will need to configure information specific to your network deployment in order to pre populate project, network, subnet, image, keys for the admin tenant.  Typically a script called init-runonce is used to do this.  This is typically a one time configuration for the Admin tenant.
  * Runs kolla-ansible post-deploy to genterate credentials in /etc/kolla/admin-openrc.sh
  * Executes init-runonce with information specific to our network deployment in order to prepopulate project, network, subnet, image, keys for admin

Additionally `init-runonce` is executed during the script processes.  Modifications will be necessary to ensure a proper functioning OpenStack deployment after installation.

* [init-runonce](init-runonce)

Theses changes represent the Network information of the subnet of the active interface with a range of IP addresses that can be used for assigning `floating-ips` to the virtual machine instances.  The changes used in the this example are the following:

```
EXT_NET_CIDR='10.1.1.0/24'
EXT_NET_RANGE='start=10.1.1.210,end=10.1.1.240'
EXT_NET_GATEWAY='10.1.1.1'
```
