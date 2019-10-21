#!/usr/bin/env bash

cd /var/lib/libvirt/images
virsh net-start default
#wget -cv https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-10.1.0-arm64-netinst.iso
#virt-install --name test --cdrom ./debian-10.1.0-arm64-netinst.iso --memory=8192 --vcpus=8 --disk none
wget -cv https://dl.fedoraproject.org/pub/alt/atomic/stable/Fedora-29-updates-20191001.0/AtomicHost/aarch64/iso/Fedora-AtomicHost-ostree-aarch64-29-20191001.0.iso
virt-install -name test --cdrom ./Fedora-AtomicHost-ostree-aarch64-29-20191001.0.iso --memory=8192 --disk none
