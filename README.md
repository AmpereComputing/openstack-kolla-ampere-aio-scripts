![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# openstack-kolla-ampere-aio-scripts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Scripts and information for reproducing an OpenStack All-In-One deployment on Ampere eMAG systems using OpenStack Kolla and Kolla-Ansible.

# Installation



## Operating System Requirements

* Netboot iso for [Debian Buster 10.1 ARM64](https://gensho.ftp.acc.umu.se/mirror/cdimage/release/10.1.0/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso)

## Building Kolla Images

## Deploying Kolla Images

<script  id="asciicast-276985" src="https://asciinema.org/a/276985.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

## Script Assets

* [001_enable_docker_and_virtualization.sh:](001_enable_docker_and_virtualization.sh) Installs prerequisite packages and configures docker and kvm virtualization
* [002_install_kolla.sh:](002_install_kolla.sh) Installs Kolla and Kolla-ansible from source
* [003_build_containers.sh:](003_build_containers.sh) Uses `kolla-build` to build Debian containers from source on the deployment host.  Process wrapped in `asciinema` for recording.
* [004_kolla_pre_deploy.sh:](004_kolla_pre_deploy.sh) Runs kolla-ansible generate-certificates, prechecks, bootstrap-servers
* [005_kolla_deploy.sh:](005_kolla_deploy.sh) Runs kolla-ansible deploy wrapped in Acsiinema for rerecording the process.
* [006_post_deploy.sh:](006_post_deploy.sh) Runs kolla-ansible post-deploy, and init-runonce.
* [007_terraform.sh:](007_terraform.sh) Installs terraform, downloads terraform-openstack-images, and deploys to OpenStack AIO
* [init-runonce:](init-runonce) Modified init-runonce with values that will work on network.

### globals.yml

* [etc/kolla/globals.yml](etc/kolla/globals.yml)

Kolla globals.yml configuration file used to produce an OpenStack All-In-One.
The modifications to the global.yml to produce a working AIO are as follows.  
Please note that the neutron_external_interface is actually a USB nic that was used to provide a second interface on the working system.   The interfaces must be changed to the appropriate working and active network interfaces for the deployment to be successful.

```
kolla_base_distro: "ubuntu"
openstack_release: "8.1.0"
kolla_internal_vip_address: "10.1.1.88"
network_interface: "enp1s0"
neutron_external_interface: "enx00051bb122ed"
nova_compute_virt_type: "kvm"
enable_haproxy: "no"
```
### init-runonce

* [init-runonce](init-runonce)

Modified to include the subnet and gateway information for the current example.

## References

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


## Paste Logs from Ubuntu 18.04 Libvirt failures

* [libvirtd.log](http://paste.openstack.org/show/781097/)
* [nova-compute.log](http://paste.openstack.org/show/781098/)

