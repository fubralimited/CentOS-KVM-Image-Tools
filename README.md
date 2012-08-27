# CentOS KVM Image Tools

Some simple tools, instructions and images to assist with creating CentOS KVM virtual machines. 

## Installation examples using virt-install

### Simple CentOS 6.x install from a remote HTTP kickstart file, using GUID partition tables

This command will perform a text-based installation of the latest CentOS release (currently CentOS 6.3) directly from a public HTTP mirror without requiring any installation CD/DVD. A virtual machine will be created with the given settings, and output from the installation will be sent to your terminal rather than a VNC session.

    virt-install \
    --name "centos6x-vm-gpt" \
    --ram 1024 \
    --nographics \
    --os-type=linux \
    --os-variant=rhel6 \
    --location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
    --extra-args="ks=http://fubralimited.github.com/CentOS-KVM-Image-Tools/kickstarts/centos6x-vm-gpt.cfg text console=tty0 utf8 console=ttyS0,115200" \
    --disk path=/var/lib/libvirt/images/centos6x-vm-gpt.img,size=10,bus=virtio,format=qcow2
    
Once the installation is complete, you can connect to the virtual machine's console with:

    virsh console centos6x-vm-gpt
    
If you want to delete the virtual machine, you can do so with:

    virsh destroy centos6x-vm-gpt
    virsh undefine centos6x-vm-gpt
    rm /var/lib/libvirt/images/centos6x-vm-gpt.img
    
### Create a CentOS 6.3 Golden Master Image

