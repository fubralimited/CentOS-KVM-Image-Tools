# CentOS KVM Image Tools

Some simple tools, instructions and images to assist with creating CentOS KVM virtual machines. The following guide assumes you have virtualisation tools such as virt-install and libguestfs tools such as virt-sparsify installed. If you don't, then install them with...

    yum install libguestfs-tools
    
…or the equivalent command for your distribution of choice.

## Testing virt-install

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

## CentOS 6.x Gold Master Image

### Creating a CentOS Golden Master Image    

1) Install a fresh virtual machine that will become our base image

    virt-install \
    --name "centos6.3-gold" \
    --ram 1024 \
    --nographics \
    --os-type=linux \
    --os-variant=rhel6 \
    --location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
    --extra-args="ks=http://fubralimited.github.com/CentOS-KVM-Image-Tools/kickstarts/centos6x-vm-gpt-selinux.cfg text console=tty0 utf8 console=ttyS0,115200" \
    --disk path=/var/lib/libvirt/images/centos6.3-gold.img,size=10,bus=virtio,format=qcow2

2) Make sure you are inside the new guest, then apply the latest package updates from yum…
    
    yum -y update
    reboot
    
3) The guest should have rebooted, once it comes back up - log in, and then remove any old kernels to free up some space (assuming the kernel was updated in the previous step

    yum remove $(rpm -q kernel | grep -v `uname -r`)
    
4) Run the create gold master bash script to remove MAC address references etc.. then shut it down.

Note: If you are using a newer version of libguestfs-tools then you could try using virt-sysprep -a imagename instead of the create-gold-master.sh script. It seems there is a bug with the earlier versions, like the one shipped with Ubuntu precise, whereby it wouldn't detect rhel OS types, and therefore doesn't run the parts to wipe the hostname or remote the mac addresses references - https://bugzilla.redhat.com/show_bug.cgi?id=811112.

So if you are using Ubuntu Precise as your hypervisor, run the following commands from within the guest.

    wget https://raw.github.com/fubralimited/CentOS-KVM-Image-Tools/master/scripts/create-gold-master.sh;
    bash create-gold-master.sh
    shutdown -h now
    
Whereas if you are running Centos 6.3 as the hypervisor (with the newer version of libguestfs-tools), you can run

    shutdown -h now
    virt-sysprep -a /var/lib/libvirt/images/centos6.3-gold.img
    
    
5) From the hypervisor sparsify and compress the VM image

    cd /var/lib/libvirt/images/;
    virt-sparsify --format qcow2 --convert qcow2 centos6.3-gold.img centos6.3-gold.img-sparsified
    qemu-img convert -c -p -f qcow2 -O qcow2 centos6.3-gold.img-sparsified centos6.3-gold-master.img
    
In theory virt-sparsify should not need the --format and --convert arguments if you want to preserve the format as it should be able to auto-detect, but it seems the auto-detection doesn't always work (works on Ubuntu Precise, but not on Centos 6.3).
    
### Creating a new guest using a copy of the Golden Master image

Copy the image

    cp centos6.3-gold-master.img centos6.3-gold-copy1-nobacking.img
    
Create a new guest using this image with virt-install --import

    virt-install \
    --name centos6.3-gold-copy1-nobacking \
    --ram 1024 \
    --os-type=linux \
    --os-variant=rhel6 \
    --disk path=/var/lib/libvirt/images/centos6.3-gold-copy1-nobacking.img \
    --import

### Creating a new guest using the Golden Master as a backing image

Create a new image using qemu-img that specifies the master as the backing image

    qemu-img create -f qcow2 -b /var/lib/libvirt/images/centos6.3-gold-master.img /var/lib/libvirt/images/centos6.3-gold-copy2-master-backed.img

Create a new guest using this image with virt-install --import

    virt-install \
    --name centos6.3-gold-copy2-master-backed \
    --ram 1024 \
    --os-type=linux \
    --os-variant=rhel6 \
    --disk path=/var/lib/libvirt/images/centos6.3-gold-copy2-master-backed.img \
    --import

## Working with images

### Resizing a virtual machine image

Creating a new guest with a different size to the original master image is fairly straightforward. 

Firstly create a new empty image file, with the correct size you would like

    qemu-img create -f qcow2 centos6.3-gold-resized-20G.img 20G

Then run virt-resize to make a copy from another virtual machine image and expand the partitions within it to the size of the new image.

    virt-resize --expand /dev/vda2 --LV-expand /dev/vg_main/lv_root centos6.3-gold-master.img centos6.3-gold-resized-20G.img
    
Then import this new image into KVM as normal

    virt-install \
    --name centos6.3-gold-resized-20G \
    --ram 1024 \
    --os-type=linux \
    --os-variant=rhel6 \
    --disk path=/var/lib/libvirt/images/centos6.3-gold-resized-20G.img \
    --import
    
### Adding VNC graphics 

If you want to add a graphical VNC console to an existing guest that doesn't currently have one set up, you can do so by editing the domain xml and adding a graphics line. Any time you change the XML config, you need to run the virsh define command again. 

Shutdown the guest

    virsh shutdown centos6.3-gold-resized-20G

Edit the XML file

    vim /etc/libvirt/qemu/centos6.3-gold-resized-20G.xml

Add the following line in the devices section

    <graphics type='vnc' port='-1' autoport='yes'/>
    
Import the updated guest xml configuration

    virsh define /etc/libvirt/qemu/centos6.3-gold-resized-20G.xml
     
Start the guest
    
    virsh start centos6.3-gold-resized-20G
    
If you are connected over SSH, make sure you have X11 installed on your client machine, and that you connected with X11 forwarding enabled (e.g. ssh -x). You should then be able to connect to the VNC graphical console with

    virt-viewer centos6.3-gold-resized-20G
    

    
