![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# Deploying an Openstack All-in-One on Ampere Aarch64 Servers

## Table of Contents
* [Introdocution](#introduction)
* [Kolla/Kolla-Ansible Primer](#kolla/kolla-ansible-primer)
* [Requirements](#requirements)
  * [Operating System](#operating-system)
* [Host configuration and Software Installation](#host-configuration-and-software-installation)
  * [Prepare hosts file](#prepare-hosts-file)
  * [Preparing the Python stack](#preparing-the-python-stack)
  * [Virtualization and Docker](#virtualization-and-docker)
  * [Disable host services](#disable-host-services)
   * [Libvirt](#libvirt)
   * [Open-iscsi](#open-iscsi)
   * [Disable Apparmor libvirt profile](#disable-apparmor-libvirt-profile)
  * [Install Kolla and Kolla-ansible from source on Debian](#install-kolla-and-kolla-ansible-from-source-on-debian)
  * [Using Kolla to build container images](#using-kolla-to-build-container-images)
  * [Kolla-Ansible Configuration ](#kolla-ansible-configureation)
* [Running Kolla-ansible](#running-kolla-ansible)
  * [Kolla-Ansible Pre Deployment](#kolla-ansible-pre-deployment)
  * [Deploy using Kolla-ansible](#deploy-using-kolla-ansible)
* [Post Deployment](#post-deployment)
  * [Configuring OpenStack for first use](#configuring-openstack-for-first-use)

## Introduction

Ampere is known for leading the industry with our Ampere(R) Altra(TM)Arm64 processors optimized for cloud workloads. In many discussions with opensource developers, we get asked for some usescases that can take advantage of all the compute cores provided by Ampere(R) Altra(TM)Arm64 processors.  Obviously virtualization and containerization immediately come to mind as well suited tasks. OpenStack is a great workload to test and show the capabilities of Ampere servers because it provides a management API framework for providing different cloud related services/analogs to Amazon/Azure/GCE that can be deployed within one’s own datacenter.    Once  deployed, one can utilize devops tooling with the provided OpenStack APIs to quickly deploy virtual machine resources at scale. 

This is a first in a series of “how to” blogs that will look at OpenStack.  This specicic blog focuses on an OpenStack all-in-one deployment for servers with Arm64 processors.  Recently OpenStack announced it is now becoming the Open Infrastructure Foundation, widening its focus to a variety of open-source cloud technologies. It will provide an open environment for enabling new emerging use cases such as AI, edge computing, 5G and cloud-native applications.

While researching the best and efficient way to get to a working OpenStack deployment for Arm64 based platforms, I went through different combinations and permutations of the different deployment tools for deploying OpenStack. The steps here are the easiest and fastest to achieve a working OpenStack Cloud which provides basic virtualization functionality. Currently, [OpenStack Kolla](https://opendev.org/openstack/kolla), and [OpenStack Kolla-Ansible](https://opendev.org/openstack/kolla-ansible) are the only ways to deploy an OpenStack AIO on Arm64 systems.  OpenStack-Ansible was attempted but wasn't successful due to lack of complete multiplatform packaging and hard coded requirements for x86 systems. Another reason to use [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) for Arm64 is that the community maintains these projects in an upstream continuous integration ensuring a functioning OpenStack deployment for Arm based architectures.

## Kolla/Kolla-Ansible Primer

A basic understanding of the parts comes handy for better understanding of the deployment process. [Kolla](https://opendev.org/openstack/kolla) is used to build containers for the OpenStack services from source.  [kolla-ansible](https://opendev.org/openstack/kolla-ansible) then uses the previously built containers to deploy a containerized OpenStack All-In-One (AIO) on the Ampere server. At a high level, [kolla-ansible](https://opendev.org/openstack/kolla-ansible) is essentially a tailored deployment of ansible specifically for installing and managing an OpenStack deployment lifecycle.

## Requirements

As anyone who has attempted to install and deploy OpenStack knows, there are supported operating systems, hardware patforms, and components that can be mixed and matched in multiple combinations and permutations. However for the purposes of this, we are going to deploy the system and OpenStack services necessary to allow us to deploy Arm64 virtual machines on a single server.

### Operating System

Currently and empiricially, [Debian](https://debian.org) is the best choice for base OS platform for running the cloud and for using kolla-ansible with Arm64 platforms.   Given that RedHat and CentOS recently released "Offical" Arm64 based distributions, there may be better experiences with other platforms in the future.(This sentence is confusing!)

The server used for the writing of this was installed with standard Debian operating system version 10.x for Arm64 from a netboot installation ISO. Debian is one of the operating system platforms supported by [kolla-ansible](https://opendev.org/openstack/kolla-ansible). Debian releases 10.1-10.4 have also been tried with no perceivable difference between iterations when used in this context. The OS is installed in a minimal configuration, only including a OpenSSH server as the additional software selection.

```
* Netboot iso for [Debian Buster 10.1 ARM64](https://gensho.ftp.acc.umu.se/mirror/cdimage/release/10.1.0/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso)
```

## Host configuration and Software Installation
After you have a functional [Debian](https://debian.org) deployment, you will need to log into the new installation as the "root" user.  All of the the following steps in this document assume that you are using the "root" user account throughout the deployment process and not running the commands via sudo.

### Prepare hosts file

Modify the `/etc/hosts` file and comment out or remove the line that begins with 127.0.1.1. This is necessary as it causes issues with the kolla-ansible deployment process and the ability for containers to resolve names back to the host. Removing it ensures a smooth run of kolla-ansible.  The following sed line will comment out any offending line.

```
sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
```

### Preparing the Python stack

[Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) are both Python based projects.  Therefore, our first step after installation is to prepare the python software stack and install any additional python dependencies.  To keep things on a more modern track, we will first switch to using Python3 by default on the base Debian platform by running the following commands.

```
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
```

Next install the required python development packages from default Debian package repositories.

```
apt-get install -y python3-dev python3-pip python3-selinux python3-setuptools python3-virtualenv libffi-dev gcc libssl-dev 
```

When using [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible), it is best to use the lastest version of pip, python's package management utility.  We will use pip to upgrade pip before installing any additional python from package or from source.

```
pip3 install -U pip
```

### Virtualization and Docker

Once the changes to python stack have been made, the next step in the process is to deploy additional software requirements from the Debian package mirrors.  Again no changes to the default Apt package repository configuration were necessary.

Installing some useful tooling to aid during debugging, troubleshooting or collecting output, is always useful.  These packages may not be mandatory, but were useful in general during this process.

```
apt-get install -y aptitude screen rsync git curl byobu asciinema tcpdump
```

We need both container engine and virtualization enabled on the host to deploy [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible). So the next step is to install docker and other virtualiziation tools from Debian packaging.

```
apt-get install -y docker.io bridge-utils cpu-checker libvirt-daemon* qemu-system qemu-efi virtinst virt-manager open-iscsi
```

### Disable host services.

#### Libvirt

In the previous steps, we essentially installed the software necessary to configure hypervisor functionality on the host platform.   However because all the components of the OpenStack [kolla-ansible](https://opendev.org/openstack/kolla-ansible) deployment are containerized, the packages essentially are used to layout the filesystem structure that will map back into some of the containers providing functionality.

Configure the previously installed libvirt services for kolla by disabling all of them. The libvirt services currently running on the host can be disabled with the following commands.

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

The Iscsi services are used when running OpenStack Cinder in order to provide block storage services to OpenStack instances.  Although we may not be using them yet, we will install and stop all open-iscsi services to be prepared for when or if we want to try cinder later.

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

Install ansible from pip packages.  Currently ansible has major changes when moving from version 2.9.x to 2.10.x.   At this time Kolla-ansible is not compatible with the newer 2.10.x ansible version and only supports ansible 2.9.x.

```
pip install -U 'ansible<2.9'
```

Install Kolla and Kolla-ansible from the local git sources.

```
pip install ./kolla/
pip install ./kolla-ansible/
```

Prep the Kolla configuration directory by creating the directory structure.

```
mkdir -p /etc/kolla/config
```

Copy the default globals.yml and passwords.yml into the kolla directory.


```
cp /usr/local/share/kolla-ansible/etc_examples/kolla/globals.yml /etc/kolla/globals.yml
cp /usr/local/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla/passwords.yml
```

Copy the default kolla-build.conf file to /etc/kolla

```
cp /usr/local/share/kolla/etc_examples/oslo-config-generator/kolla-build.conf /etc/kolla/
```

Now that we have completed the preparation of the system we can move on to building OpenStack container images.

### Using Kolla to build container images

The key distinction between [Kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) is that [Kolla](https://opendev.org/openstack/kolla) provides the tooling to build container images for OpenStack services from package or source on multiple linux platforms.  [Kolla-ansible](https://opendev.org/openstack/kolla-ansible) provides the tooling for deploying the images built with [Kolla](https://opendev.org/openstack/kolla).  As such, container images can be built and rebuilt at any time through the use of the `kolla-build` command.

As mentioned [Kolla](https://opendev.org/openstack/kolla) supports different operating system options as the base Docker container image when building OpenStack containers.
As a side note, during the process of building this, both Ubuntu and Debian were attempted. Debian was fully funcitonal but Ubuntu 18.04 was unable to sucessfully deploy a virtual machine with Libvirt running containerized.  Obviously this may change over time.

Building container images using kolla will take some time, as all OpenStack containers images need to be built. Customization of the container images during build are outside the scope of this document. Please refer to the upstream Kolla documentation for more information.

To begin building contantainer images using Debian as the base operating system and using OpenStack sources instead of prebuilt packages, run the following cmd.

```
kolla-build -b debian -t source
```

### Kolla-Ansible Configuration 

[kolla-ansible](https://opendev.org/openstack/kolla-ansible) configuration is done via the '/etc/kolla/globals.yml' configuration file. This file contains options for tuning which OpenStack features and services get enabled during the deployment. To configure an OpenStack All-In-One a basic globals.yml with the following configuration will produce a working OpenStack deployment with features to support virtualization on KVM.

```
kolla_base_distro: "debian"
openstack_release: "9.2.0"
kolla_internal_vip_address: "10.1.1.88"
network_interface: "enp1s0"
neutron_external_interface: "enp1s1"
nova_compute_virt_type: "kvm"
enable_haproxy: "no"
```


## Running Kolla-ansible

### Kolla-Ansible Pre Deployment

All the openstack services require passwords for authenticating to each service endpoint.  A /etc/kolla/passwords.yml file containing all the service passwords is needed.  Luckily Kolla-ansible includes a tool for managing and generating all these indidual service passwords and for creating the /etc/kolla/passwords.yml file.

```
kolla-genpwd
```
 An example of the content within the `/etc/kolla/passwords.yml` file can be seen by clicking below.

<details>
<summary>/etc/kolla/passwords.yml</summary>

```
aodh_database_password: dhoz7ORFyLOqfnuWAYXBB296jMjRgP1d74l0jWLp
aodh_keystone_password: ucvmxXGmYUG6FxI6bGl2HmkrgD0hWyABQNyGMAo9
barbican_crypto_key: nReGUAK1l9qFJT7DCRaDrp4iJIN_1yK5fZxv8il7-U4=
barbican_database_password: jjxm51MMWV2BHLnUuUYAGm13CemDaTu2WU8VnMeT
barbican_keystone_password: R0uQPRKUd5igbUEO3PVNpUcKALmUn6G0Dgk403s2
barbican_p11_password: cFznxU879wgBCOXlJmgcXPGBpIgjkdMrk3LzCfli
bifrost_ssh_key:
  private_key: '-----BEGIN PRIVATE KEY-----

    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

    BgdwDg3hugMJGTj0f1Frt8P1zrccliE=

    -----END PRIVATE KEY-----

    '
  public_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPrmL5Px74QKxrdwBCBx9L2J6r9aX9e8V7gQWsK1Eb+c4ZaQEydL5+kWQ3wsjeSBJPDTghT1bYCVRDkwwBFfbnTL9QuRM4r0wplGt250BTayNTTwbIfaBLs/p003MB+a0aw/3eHqEylKTBgQ99qBs9tlS3KqI2M+Rb3xKfh8R6zSl7taX1MrSd0zEY680c1y8c1eOz3KY3IEvyk2W3xdU5Zgt/J6FTzSZBxNLAPT+NABlP0CHMZ5HXSul76jSh5fdPTYWd0ADCkosd42C8ytjYuFgMHXeFSY5RqvTbGsyuFzjnwiPsr6Zjmkwk0fQDYsPr+jIqcmVv42u8U4KQSSAPGZNqhP3Rm4XqYg9V3gCfLTOogxwnZ7kqeKSpTciPx5T77ToC9jZJWKNhI18QDI3DU2vJVGMWyQmvGwavXG8bnvjGrjC7LDDaI24zyu0v8XM2JcnhCM+h7BYvlvaDKsvHd+LW4Uo6pfRqdCmhA7Ob+M2/jHHDEKEZ8hAHwX4i7XwyJG9hLmWueRk7OlkIfBa2iH0inS3Ahm9tCGP8jJ4588kTLNzeXnG3+k7jDHBixa+bq/QNSWTCCSQ4V16AT2bJEa0pSBE8wnbMee8A6PoUvgQy0LDY6bQZnl9/9mMSZcjEcm0THcUwUw69N2H6AKgtGWOYLoD2PyPM+20E25mosQ==
blazar_database_password: oImIWGmKXaAE6K02gzoLj6bPx25wRlhiHmWT8Gva
blazar_keystone_password: 5OulAhsjAAtZ1fPXuKiCdowSEoEkhT9CGYp5njjR
ceilometer_database_password: TCXzauRPZ6Msaoo6jTADuKycXk2WuTL2dTvyp0RL
ceilometer_keystone_password: kVKf7hv3ducYVkG0xTd43fyA9H15T9Q1MeFddaoU
ceph_cluster_fsid: 0eb5bab7-5509-40e1-8a76-21f0a72cb143
ceph_rgw_keystone_password: GfIb4pyMz5qIf9VdHFBTsKS44pGRxyQIUQCipWTK
cinder_database_password: 5l1h3isiHGni49elavAXoSBzEZpNbcG5zuxk4EPj
cinder_keystone_password: o28R0Q1BXvqDb8kPMr8GvjsNZQNkukFZwMwMkjc0
cinder_rbd_secret_uuid: cf2637c6-e7b4-45d6-acf2-cbce056b8894
cloudkitty_database_password: IZjVrdgRiY9v04dxAxHiFpqI8BwzXI08Gr6JARe3
cloudkitty_keystone_password: 9sxFYAKzyJvNrdZhmPpEBYTNhRqnZv0pKkwU5vHn
congress_database_password: BqRHvyUJY62SQQwQHsD2epzobcuVtKjJc2FsWqVk
congress_keystone_password: I35R6Rwm76Wat0cx8BHkA20A4AqV9chFNsKn7nXY
cyborg_database_password: Aj0eAfdzlWCJiThYeIbnqqSkzpZ273ntA7ECs6sV
cyborg_keystone_password: lcu8eeb2H2YC5Izkj5sGRNuUOBDh0AF1IOFDZHFh
database_password: zgaNxxdjQ1T6Sd63f1RfuXfTpbpWFxEWuvu8sgAC
designate_database_password: YYMnkPiluYcihERvui0TWmJaahkTKK2jQ8Ms28aN
designate_keystone_password: MnNyquw9VDJBfMkfWNlTFqAzrE0fCpNwyoWHFvyi
designate_pool_id: 33a0129e-3d15-44ee-9a69-bcc52d1ccef6
designate_rndc_key: b36314d93d7381f897099413b85d9f8f
docker_registry_password: null
etcd_cluster_token: ldLYZhEFKZrGPCYBkKOxmuMRPl7E6Bdub6siIIE8
freezer_database_password: fwluBGSUgPH2EMI5pL6JffqNcaI5zHsvcoWLMurs
freezer_keystone_password: M45CPCvxlthEW5ivfZpoZwh4pZrSgBKtIKQSAnuC
glance_database_password: SzZRkXAwWyMLWRxntMCY3kJhmqND4ftWljckGSlC
glance_keystone_password: w0q6ke9FXamQnUwnv4sbIR2skfqZno4F13SbwyR0
gnocchi_database_password: 8d8YLfhMYMgL1F9b20S3GJe3WLo92H0z7rs38rCo
gnocchi_keystone_password: xbvO4CVzQVIXMgYkLgHnX391fffDSRonEtpeBNVV
gnocchi_project_id: e30b743a-a379-4dba-a6e3-ef4644b0b6af
gnocchi_resource_id: b0e6f869-938d-4a59-bdb5-53ab692ea58e
gnocchi_user_id: 1234cc9e-b6bf-4074-ba63-1706de8a8972
grafana_admin_password: mMVGcAOhpbK24yJePtkPC9tIJw261O5FX5aVpzpN
grafana_database_password: k2FXJevsEbP0igmm45TUVkFAg5hxv5Vx2nFe6TgH
haproxy_password: dCc3QnvWoQwn3lOjdGweZDReqPNHr1l7ALYLZ215
heat_database_password: GXIN5oSQwj8oh2UhGWLR5zLR5NecRUyDqepBhMmC
heat_domain_admin_password: NO4pvlHU6OW7XR74tPJWQpSSNGtiWeZMj8sLkqjs
heat_keystone_password: TXYmkSXTShcjubtvY1I6m5Ayq7dvJ78CICNIwz7G
hnas_nfs_password: HsdRYOc6i3dB0F6VEFsXBy1gqvzIQ8uVjyvGBRkA
horizon_database_password: aMk0Tzr7VmX9AjqVxyX0MiYZtvGRvp1CSu6O4S4B
horizon_secret_key: UWeJV1T3cEctquSOwSHAfLwSjUWHfFQbC35ifd1f
infoblox_admin_password: 7RFXQ7FjcF187DJLmVFVSt3VtpADeqU6mfDX2ziU
ironic_database_password: aqNVKpZ2nIJ0DonLOH0OhcmsXT99yv0VbKruZenw
ironic_inspector_database_password: 8ehpiZIB73WXg8FUZgkQDUyZyWOjCXbl2OVwlNZC
ironic_inspector_keystone_password: ZfodX2aLGH5gTkaTtByHAwFkmw3fyURIzDyA1v3G
ironic_keystone_password: 2gii1DRsTKPX3ZZ4Lg359iVrrW5RSyDdTz4BkFkx
karbor_database_password: aeNPUpIviy66Lwyr5KBY3GIs4V4bvdepB7GDG4XS
karbor_keystone_password: zVxnfWzI9hwPIy4il7IXPgBXQHBBzsHNoj2siD7a
karbor_openstack_infra_id: 99300154-34cc-4438-81fb-d8f596ee1024
keepalived_password: irT5cg9dM5PqwohnwZjlbZ1GWpl5RUkKoaqkdStF
keystone_admin_password: xJZDDBhPbzdOvKQUGlotOLZtSllmFY5yuSUvZHHp
keystone_database_password: AxkbYFhE4f2vNXJPd5SLOSl1GREypI80u4NktbHE
keystone_ssh_key:
  private_key: '-----BEGIN PRIVATE KEY-----

    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

    +83YraJGT3FjZRShNiIcqOxa8Mg8bLle

    -----END PRIVATE KEY-----

    '
  public_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9gvQVcemNwhjtmUIX2yTy42c1AKWmMYglnfRni+3Ex6Z52tfDJHCzEW0Z5jXbBLuPYn5W8akLyKb7Vby70b/lIxV8INeIhxrjYBG+aa+T0VHA5oPChmNge91zIUcEHcaVNqawkOWkS7hGmxr4gLcZ+t6STanBtkeJeLH/M91EmEJ0ch5c6YxFE9SqAs4u7/SZu4Ez/fPJoHbm2jc/Njx762JEjK+NF0jYqVDO9EVzGFwrQncmgwFqJmel4n0IJJu/oVRDEPj1uGSexXUVvdg8r1WowTQyusEBWdVZyqOqmJ74cmJYeTZurQovftOS6z5QI5OteFT3xZk3SnAfJXGyAqSS0rmTQ8cgIWCeOHbcqs3PgIBks5bH72it3lv4MahFx2EIdnnIl+GePkQbskLyylIUKyqXGK9kxqwIUWjjy4ZKQu86+URJXhouN3gpgDQKVajUStTLfDYlJM3Dbsi7v7Pjdli9DnyDtsx02+Zvs78D/KolU1dzQo5toVD6oQ2OIJWckFrjogrVdcbzgFSkJcBKyH3x4pt++xoyayigngpxzvo+Ta+mtEvZxc+tNTX9Q00VzmjI+7vARySXOA6wQgsPI3PeSSamDWzowewtfno5zIhlHc3dXpN+1KI/cAvIIVF2Mhc6mo2MVj1bXJLLihpF/kZbTFgTklpz7zZatQ==
kibana_password: ivNMRiv3fQY0ecCDZ2xSIF1OoqDflpYsjEvMZhXi
kolla_ssh_key:
  private_key: '-----BEGIN PRIVATE KEY-----

    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

    6IM6BmpBffFBwIkPj1yT3974AQi4PWE=

    -----END PRIVATE KEY-----

    '
  public_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2cbwQcX9RHUIe23EG/J6VeKSc8TpSWjk9QVZrTFQyix5cTKsFb7jJTV+OliPwjbGi3QZYfEQCXteHQmQZwviHzGzv/2h0PJFcJfYM+A/jsoZRUkpya6P7XlAeMsZi2oqID4DtiRWiON10frDlJKg0MInqz+W6lF7+zqL1QQZBwCW2dQpjFnLgEe7p6NF3Ke3Zb337WkunIwt8KXClD/NnsX2KlZE+NIyxz3cZA3e06r5xWzFLu7bYTeeW8xXCvQx6BIeb9ZkUhgnAhHfbO0sDD00vXYfwtSsFR0Fsu9sifwEN4rBg+M57MbjY0yftl4Res4erGsB+l6PfeYX4G3jPOKXw2OJghffaPgt0h5Ga/wG0x/K0bHlJx0+D/SEFqvKKxIUfQ52OkL1D9rcKjLzau+NMSXRwo1axZt6cRwZ14F0Y1FSowf5L8Qo5UcYzUBGfMEcZJfvNj2f3MZhjH6eJ8DuW/2QR2v7YcrPTAV7B5irCv8VSLxYss6vvqL/q+lzPyA/IhqNnRtSmqh7/S2L/GoHAfVoZkuIbVJfyNicJ7hwUO03HLm3myhz+V+Ej+WRaYOXfrRItxmvQ4fNldJa+y1NhPSMaDpzsL8eBZESreyQdBfD/QhfqouHExAJoPlVrHVRoD9mVSs2EJE1zkWGwluBPYTtywNV/3JKl09tPkQ==
kuryr_keystone_password: emYUlq4sdjSfSWMO4c9yBKTOXqmb87piFXZIavan
magnum_database_password: djmo5lCPab9RTJGADRH3YFVm1Zagyc1x5kOx87q7
magnum_keystone_password: x3oJvQuNtKRcH8dFELkbAcRKmN5B3xeR9CK2CneO
manila_database_password: 4F7KFB7Q1IGmiEH97jiNgdc4bdk7T8I0Ue3HgdDe
manila_keystone_password: zSOtBfhg8zxSNDiOzv9DFiCAmQ4FjUroIdVD6UI5
mariadb_backup_database_password: SvSGNc36smRlok9iVKTFZTl5JRzyDTCxITJa6wzK
masakari_database_password: lBH56J8mospgXscyeXQQtro3G84P5TnFB7RIGEKx
masakari_keystone_password: jXlFlD6oIodYMgK5hd27lByyDqtUBopCESkdYifx
memcache_secret_key: ZL773pSj3ijFPO7sxJmnpphw3RjgAhyx6dfdqLY2
metadata_secret: 8Wggw05x1ogQ6PIW4VubWTRH3YtHkuUUDb2TH7wm
mistral_database_password: uRz8dwStWHdAWGy2CViOY1Zi10EeYm59ASOWaBlj
mistral_keystone_password: PHI38nzkzl3M3kYsMcJbpDI58iC9PHcKgshlxOqc
monasca_agent_password: Q1IwGKmn7bABe1SCzCxYDZinn3eBNlxel2faC4M0
monasca_database_password: DTFawI9YcjfPrIuFuPKuFrafuc76WekeSS90VR2y
monasca_grafana_admin_password: 4kQGZRtUeSawGLZ9HwaBSkoCEUeTospDR3XnwUAH
monasca_keystone_password: aLazBc74cq11LKoGVuse5eabwMKPNjEaPPllI0iB
murano_agent_rabbitmq_password: 68rVXrXz4c8UISNwEVZAVgra8aAJ8RjIWH0wuWAh
murano_database_password: Ia9l0IfHWLxNjOWWtLZxhMSbGiBTil3wH52mdKkL
murano_keystone_password: eMSBaXD4J9drz8FiWzZKhqNGHAGYbTS3LqBl4Co0
neutron_database_password: hggtXDmYpCZFExKGDuPGgqu2K6OOj8LdrpD0pegx
neutron_keystone_password: 1LPXDi7Sm5azoOtLto4mUxAbMjZpUrxdZ2DDC9Q8
nova_api_database_password: TRwEzntp5UZtC3Jn5JeoyHhDoAyz8ltzfq07OOvN
nova_database_password: mxEbfPWfj6cxIr8lKlnctZXlBcgElBw9iPtYta4h
nova_keystone_password: ism9IfYVwKxDOIrarZxkhyCwLhBHfRdoboWXEiJU
nova_ssh_key:
  private_key: '-----BEGIN PRIVATE KEY-----

    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

    xiD04uKYkI4HJxyjMSh1Pno4aZXz

    -----END PRIVATE KEY-----

    '
  public_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCjXm2u1kJSEv9gQ+2KetVK6fYzmG7HSt9NsKBlH2UOJJvkJmWhJAhgzHjhXrn1M5L0C81E/8FqegW6KRyuNM59+CyFHpQh/LUsMM9EvfbIMcRa8Ncj9CPWcmPEkDw59a+G72eCCptxl/Q+nwlGJ5g2CPKmiFr6gSphQCJzYKxYD6vaz0ybXo7bInEP9URkAohdd/B8C3WnIxickP6ftofGPlPXT2FVPLLFxl7ACe5pYsiodViizdtPXBmVfcQwDT0c5DqG49NaUUZbuqYZyu4iVHkxhTtzLJaavcFvQsZS21w1wJD4/E9LDLpwq2Hwn0PMvauB2sr59/9jGXSJSKidICZKb3i/Zla86bYxjnwbbqmhhNca9W1xaVQDtTDy7k2cY23zbi6Ozip223bpgReEg7BWScbKJBJonYg9vv5vABsHXr4SUCbBE8ZH0PwbJsusofoBKheihdhhi9YEnG5W9tpkL1lt7Ma5mpzSSLgN2zBNQ1GVMOogY4i4QBruclYILWTSWDoPEGVi/GoM02rHd9E4Go4YzJz8tZYEpWrFHNd92pwk/hQHScKxWP61G6NwABcxtQNAVETRrUhYebNWNCI2iliiyzbqgZv05BBJJWveBS1qcHoFVBkEp0hoxOmbC94mQWl4aazoGfZqAOmZSBEv7PwrbhFKSVBHHu0ZJQ==
nsxv3_api_password: MCThVh4QwSP6o0byJTBIvm9fOeI4WHRrUigOu68z
octavia_ca_password: bDoBDlWY1EEzyAEyucJIxhFZmfySDozK7Hb5LqgY
octavia_database_password: Ui3lQcfhrNDsOtvGiO26U44klqNoAPccj1pfGZie
octavia_keystone_password: jouUC8XedhTZUgc7DHxtLL7aPXFGRMPlClnoXdmR
onos_password: vvtarWs6rPJCIoeo8wIEbIed5H4wNS9BIIlIk8p0
opendaylight_password: pxpYPbxZG3yLc6ffaqAkwfus1x3Sdnyej3oVgKgu
osprofiler_secret: 491e710a389b291945902e6494e7a000
outward_rabbitmq_cluster_cookie: P0ig1CDg8ic7Ba8UUV8kxUmkhpX7RhhgpqXnL9MT
outward_rabbitmq_password: 96G5aSVwnKOHLuwZ54Wy8O6efcxLINQuFb5vWbCR
panko_database_password: 5LgpU7VEgjRSn604gBAVqmHJa91If3mgsNxwvcWj
panko_keystone_password: r54eoPIgpolxiXX8T2OAqHEeqR0KrRH1cgB2tBVk
placement_database_password: G2oa1vImgfrN7IvhsIl1GcIedWxYpPcOgCvoKJ0L
placement_keystone_password: UunVGAQ2U1WQUjEovETMQjvdGGkhFQeThk5MfHkj
prometheus_alertmanager_password: Iqr4RW0R4PRX7YgqNNeh3NaOcoeJdpyfvl9ytvOz
prometheus_mysql_exporter_database_password: UYerhmeGVSfVK4ApUJ3IBRXNhMoi3TTyvCiGKiWB
qdrouterd_password: zXhZf0Ley5akXiLJGXbnMV4FYnxsIqkmgaZ7PbYJ
qinling_database_password: ZcQCv6rnOlZ6qgN7RG8BsgoXPlFokt5NIkEznsnT
qinling_keystone_password: sYkHtE9ZmVJKqMSE5IEhUoiu4OuEMHBrghTqvrSG
rabbitmq_cluster_cookie: U51CVJGK8AzyUFw6O95DnwpmD9FG5N1EHf5MK025
rabbitmq_monitoring_password: vbQD7tyIU928eA4AA9YeLxvciTz0GG3elYjQr0MF
rabbitmq_password: s1gXezIUj1N4l5h3hub2F6eOv6SYB7sbMt9yaxPa
rally_database_password: ut4rRFuQrZa7orCw6Qzmme20rhiB2BxxRv0G0hx6
rbd_secret_uuid: cba35fff-7d82-4f08-b142-6e85b356002e
redis_master_password: ywq5ZiceTceBJXCTTzuA8SOZbouIuEE08tCJg5AV
sahara_database_password: UBi7eqI4C1MbTCs0dJq3jkF5fU437EtofFJSdFpz
sahara_keystone_password: rvyhcKwm5Q5NwMTenmx6CeJj7QLxbWwm3x8pGZSf
searchlight_keystone_password: 0BrHGDgGnJiKjrmTGmtb8pyjRlVHMi3PijDPYEt2
senlin_database_password: dGgoscn91DxLHzeBzH9wTOd4FOuoH3u5aZ3t8D3d
senlin_keystone_password: 5NjPTyl6HhIjZ8HxyxlamxfmOJpScNyq9MWTLKfq
solum_database_password: Qe4E8hPD1COtNlQnz9LI6AP6yaDUpBmMXXaDOkjb
solum_keystone_password: gKYdtDV6nhzJtkdsXu8N57Ts77atadLibbY0pJZ2
swift_hash_path_prefix: jw2qCQbN3XeojZZWmROYNRT3LmyxtmbTloIRphFN
swift_hash_path_suffix: vIGOeT80U64Wubg9UM4WxLlysvDfdoUTqXmMg5nN
swift_keystone_password: tf9qEKKL1L5vWSXKUdarPoljhjWOpLUthMLj9jEj
tacker_database_password: OoPQVlJEsu0r3jSydXAeArIgKXk32pCZ7xtTRhfi
tacker_keystone_password: YRei6lNtSIVsyI67oqno7l0ZgkDW9toAkGzjBLzc
telemetry_secret_key: ge7wZQGb3l7cFIhUU1e5hUJnXOlpLaSklJkRCVkw
trove_database_password: 5G7LABmFEvD1qrYy2vxFp7cS99pLTpN8xhpG9tnQ
trove_keystone_password: KOhnznRX25LUlbRJmLePrYP2Q2sYfeVU4HvDhb8C
vitrage_database_password: XnkCqdYrfG1NimLcVsxbrnnmKQJQnVBtePDfLDuU
vitrage_keystone_password: AD20TuHxX3GUpbiR6081GSKxVSBtcjR7OmWLauVh
vmware_dvs_host_password: reP0eaTWpOcRdGrDb9fzvMfOhOxB8mwhG5D06tCk
vmware_nsxv_password: U3D8dKybVm0muOHkdoMTigBgSxC847vllFf1wImu
vmware_vcenter_host_password: xpDbhCayEx3Zmv23s8C8ETz9uEfNBmCfdcEAyO02
watcher_database_password: TPM2MqqOP3Z1msLQ1WLBX3xoOzHmakZg3NLspsWw
watcher_keystone_password: xRKEA3bGlkf2FyBg2yQGB4Q8iiS6vVaVBwNXHYnO
xenserver_password: y7a9hMwhtrgfKz7txQ1A4uZ4ERxnOMEJtyjTSnTE
zfssa_iscsi_password: 41BRHz60pFEoGYt89BaqZ0PdXDYIz7jvQlE9LEkO
zun_database_password: KT5cFDNzyGDVUZ2mJjwy7ixVMXAsNCe6FhWBboIc
zun_keystone_password: 6KD0kr4ihQ06YtnTmjqiw35JFK0f2eEgShyvwhve

```

</details>


After passwords are generated, it is also necessar to generate SSL certificates for use by the deployment.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one certificates
```
Once [kolla-ansible](https://opendev.org/openstack/kolla-ansible) has created the certificates we can now bootstrap servers with the necessary requirements.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one bootstrap-servers
```

Running prechecks validates everything prior to running [kolla-ansible](https://opendev.org/openstack/kolla-ansible) deploy commands.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one prechecks
```
### Deploy using Kolla-ansible

To Deploy OpenStack executing the folowing command:

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one deploy
```

### Post Deployment

Once the deploy runs finishes you will also need to generate the authentication credentials. The `post-deploy` option for kolla-ansible creates a file in /etc/kolla/admin-openrc.sh which can be sourced to set all the necessary environment variables in the current session to allow the admin user to authenticate to the OpenStack services and use openstack clients and third party tooling like terraform and packer.

Execute kolla-ansible post-deploy as follows.

```
kolla-ansible -i /usr/local/share/kolla-ansible/ansible/inventory/all-in-one post-deploy
```

The following is an example of the contents of /etc/kolla/admin-openrc.sh.

```
# Clear any old environment that may conflict.
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=aBCdefGhiJklMNOpQRSTuvWxYz1234567890AbcD
export OS_AUTH_URL=http://192.168.1.2:35357/v3
export OS_INTERFACE=external
export OS_ENDPOINT_TYPE=externallURL
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=RegionOne
export OS_AUTH_PLUGIN=password
```

When the`post-deploy` command finishes the necessary credentials for authenticating to openstack services can be loaded into current environment by running the following command:

```
source /etc/kolla/admin-openrc.sh
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
