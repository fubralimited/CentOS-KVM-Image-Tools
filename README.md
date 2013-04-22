CentOS KVM Image Tools - README
===============================

+ Name: CentOS KVM Image Tools

+ Version: 1.0.000

+ Release date: 2013-04-22

+ Author: Nicola Asuni, Paul Maunders, Mark Sutton

+ Copyright (2012-2013):

> > Fubra Limited  
> > Manor Coach House  
> > Church Hill  
> > Aldershot  
> > Hampshire  
> > GU12 4RQ  
> > <http://www.fubra.com>  
> > <support@fubra.com>  


SOFTWARE LICENSE:
-----------------

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

See LICENSE.TXT file for more information.


DESCRIPTION:
------------

This project contains some simple tools, instructions and Kickstart configuration files to assist with creating CentOS KVM virtual machines.

The following guide assumes you have virtualization tools such as virt-install, libguestfs and virt-sparsify installed.

If you don't, then install them with...

    yum groupinstall "Virtualization Tools"
    yum install virt-manager libvirt libvirt-python python-virtinst virt-top libguestfs-tools
    reboot
    
...or the equivalent command for your distribution of choice.


## Kickstart configuration scripts

The kickstarts directory contains different Kickstart configuration files to create Virtual Machine images.


## Scripts

The scripts directory contains the centoskvm.sh shell script that you can use to create a master CentOS virtual machine in an unattended mode.
This command will perform a text-based installation of the latest CentOS release directly from a public HTTP mirror without requiring any installation CD/DVD.
A virtual machine will be created with the given settings, and output from the installation will be sent to your terminal rather than a VNC session.

	sh centoskvm.sh centos_vm

Where centos_vm is the name of the virtual machine we want to create.

By default this script uses the centos6x-vm-gpt-selinux.cfg kickstart configuration file.
Fell free to create new configuration files and clone the centoskvm.sh script to set different parameters.

The main operation performed by the centoskvm.sh script are:

 * virt-install : creating the VM using virt-install;
 * virt-sysprep : reset, unconfigure the virtual machine so clones can be made;
 * guestfish : used for SElinux relabelling of the entire filesystem;
 * virt-sparsify : make a virtual machine disk sparse;

Please check the centoskvm.sh script for further details and configurations.

Once the centoskvm.sh scripts completes, the requested image file will be available on the /var/lib/libvirt/images directory.


## Useful commands

List all available virtual machines:

	virsh list --all

Start a virtual machine:

	virsh start centos_vm

Shutdown a virtual machine:

	virsh shutdown centos_vm

Connect to a virtual machine's console:

    virsh console centos_vm

To exit the console press CTRL + ]
The default user is root and the default password is changeme1122 (as defined on the kickstart configuration file).

If you want completely delete the virtual machine, you can do so with:

    virsh destroy centos_vm
    virsh undefine centos_vm
    rm /var/lib/libvirt/images/centos_vm.qcow2


For additional documentation on virt-tools please consult the website: http://virt-tools.org/

## Other Distributions

The kickstart directory contains configuration files for other distributions.
To generate a gold master image for this distributions is advisable to clone the centoskvm.sh script and change the virt-install parameters accordingly (location and kickstart file).
NOTE: When building Fedora VMs, a useful tip for switching Anaconda shells is to use CTRL+b then the screen number.

## Working with images

### Creating a new guest using a copy of the Golden Master Image

Copy the image

    cp centos6x-vm-gpt-gold-master.qcow2 centos6x-vm-gpt-gold-copy1-nobacking.qcow2
    
Create a new guest using this image with virt-install --import

	virt-install
	--name "centos6x-vm-gpt-gold-copy1-nobacking" \
	--cpu host \
	--vcpus 1 \
	--ram 1024 \
	--os-type=linux \
	--os-variant=rhel6 \
	--disk path=/var/lib/libvirt/images/centos6x-vm-gpt-gold-copy1-nobacking.qcow2 \
	--import

For other virt-install options please consult the command manual.


### Creating a new guest using the Golden Master as a backing image

Create a new image using qemu-img that specifies the master as the backing image

	qemu-img create -f qcow2 -b /var/lib/libvirt/images/centos6x-vm-gpt-gold-master.qcow2 /var/lib/libvirt/images/centos6x-vm-gpt-gold-copy2-master-backed.qcow2

Create a new guest using this image with virt-install --import

	virt-install \
	--name "centos6x-vm-gpt-gold-copy2-master-backed" \
	--cpu host \
	--vcpus 1 \
	--ram 1024 \
	--os-type=linux \
	--os-variant=rhel6 \
	--disk path=/var/lib/libvirt/images/centos6x-vm-gpt-gold-copy2-master-backed.qcow2 \
	--import

### Resizing a virtual machine image

The following instructions shows how to resize a virtual machine image:

shut the virtual machine down

	virsh shutdown centos_vm
	
change directory

	cd /var/lib/libvirt/images

make a backup of the VM for any evenience:

	cp -f centos_vm.qcow2 centos_vm.backup.qcow2

clone VM image

	cp -f centos_vm.qcow2 centos_vm_temp.qcow2

resize the cloned image (i.e. 20 GB)

	qemu-img resize centos_vm_temp.qcow2 20G

resize the partitions

	virt-resize --expand /dev/vda2 --LV-expand /dev/vg_main/lv_root centos_vm.qcow2 centos_vm_temp.qcow2

remove the original OS image

	rm -f centos_vm.qcow2

sparsify image

	virt-sparsify --format qcow2 --compress centos_vm_temp.qcow2 centos_vm.qcow2

remove the resized image

	rm -f centos_vm_temp.qcow2

set file ownership

	chown qemu:qemu centos_vm.qcow2

restart the virtual machine

	virsh start centos_vm

if the new image works fine, then we can delete the backup image:

	rm -rf centos_vm.backup.qcow2


### Adding VNC graphics 

If you want to add a graphical VNC console to an existing guest that doesn't currently have one set up, you can do so by editing the domain xml and adding a graphics line. Any time you change the XML config, you need to run the virsh define command again. 

Shutdown the guest

    virsh shutdown centos_vm

Edit the XML file

    vim /etc/libvirt/qemu/centos_vm.xml

Add the following line in the devices section

    <graphics type='vnc' port='-1' autoport='yes'/>
    
Import the updated guest xml configuration

    virsh define /etc/libvirt/qemu/centos_vm.xml
     
Start the guest
    
    virsh start centos_vm
    
If you are connected over SSH, make sure you have X11 installed on your client machine, and that you connected with X11 forwarding enabled (e.g. ssh -x). You should then be able to connect to the VNC graphical console with

    virt-viewer centos_vm


### Create and attach a virtual storage resize

create an XML configuration file for the extra storage device (edit the correct target device):
	
	cd /var/lib/libvirt/images
	nano extra_storage.xml


	<disk type='file' device='disk'>
		<driver name='qemu' type='qcow2' cache='none'/>
		<source file='extra_storage.qcow2' />
		<target dev='vdb' bus='virtio'/>
		<alias name='virtio-disk-extra-storage'/>
	</disk>


create empty image

	qemu-img create -f qcow2 extra_storage.qcow2 20G

set image file ownership

	chown qemu:qemu extra_storage.qcow2

attach the storage device to the centos_vm

	virsh attach-device --persistent centos_vm extra_storage.xml 


#### Configure the logical device 

Start and login into the VM, then:

label disk (vdb is the target device as defined on the XML file)

	parted /dev/vdb mklabel gpt

resize the partition

	parted /dev/vdb -s -a optimal mkpart primary 1 20G

align-check

	parted /dev/vdb align-check optimal 1

initialize the partition for use by LVM
	
	pvcreate /dev/vdb1

create volume group

	vgcreate vg_name /dev/vdb1

create logical volume

	lvcreate -l 100%FREE -n lv_name /dev/vg_name

create filesystem

	mkfs.ext4 /dev/vg_name/lv_name

create mount point

	mkdir -p /storage

add entry to fstab

	mount src=/dev/mapper/vg_name-lv_name name=/storage fstype=ext4 opts=defaults,noatime,nodiratime state=mounted

