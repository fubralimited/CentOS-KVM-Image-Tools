# CentOS KVM Image Tools

Some simple tools, instructions and images to assist with creating CentOS KVM virtual machines. 

## Installation examples using virt-install

### Simple CentOS 6.x install from a remote HTTP kickstart file, using GUID partition tables

This command will install the latest CentOS release (currently CentOS 6.3) directly from the Internet without requiring an installation CD/DVD.

`virt-install \
--name "centos-latest-gpt-basic" \
--ram 1024 \
--nographics \
--os-type=linux \
--os-variant=rhel6 \
--location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
--extra-args="ks=https://raw.github.com/fubralimited/CentOS-KVM-Image-Tools/master/kickstarts/centos-latest-gpt-basic.ks text console=tty0 utf8 console=ttyS0,115200" \
--disk path=/var/lib/libvirt/images/centos-latest-gpt-basic.img,size=10,bus=virtio,format=qcow2`