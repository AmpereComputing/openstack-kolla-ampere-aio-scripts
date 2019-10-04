![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# openstack-kolla-aio-scripts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Scripts and information for reproducing an OpenStack All-In-One deployment on Ampere eMAG systems using OpenStack Kolla and Kolla-Ansible.

## Assets

### kolla.sh

A simple script that will execute the necessary steps to build and deploy OpenStack via container images using Kolla and Kolla-Ansible.

* [kolla.sh](kolla.sh) 

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
