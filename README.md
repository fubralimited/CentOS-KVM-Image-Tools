# CentOS KVM Image Tools

Some simple tools, instructions and images to assist with creating CentOS KVM virtual machines. 

## Installation examples using virt-install

### Simple CentOS 6.x install from a remote HTTP kickstart file, using GUID partition tables

This command will perform a text-based installation of the latest CentOS release (currently CentOS 6.3) directly from a public Internet mirror without requiring any installation CD/DVD. A virtual machine will be created with the given settings, and output from the installation will be sent to your terminal rather than a VNC session.

    virt-install \
    --name "centos-latest-gpt-basic" \
    --ram 1024 \
    --nographics \
    --os-type=linux \
    --os-variant=rhel6 \
    --location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
    --extra-args="ks=https://raw.github.com/fubralimited/CentOS-KVM-Image-Tools/master/kickstarts/centos-latest-gpt-basic.ks text console=tty0 utf8 console=ttyS0,115200" \
    --disk path=/var/lib/libvirt/images/centos-latest-gpt-basic.img,size=10,bus=virtio,format=qcow2
    
Once the installation is complete, you can connect to the virtual machine's console with:

    virsh console centos-latest-gpt-basic
    
If you want to delete the virtual machine, you can do so with:

    virsh destroy centos-latest-gpt-basic
    virsh undefine centos-latest-gpt-basic
    rm /var/lib/libvirt/images/centos-latest-gpt-basic.img