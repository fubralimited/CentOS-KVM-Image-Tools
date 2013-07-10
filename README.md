CentOS KVM Image Tools - README
===============================

+ Name: CentOS KVM Image Tools

+ Version: 1.0.000

+ Release date: 2013-04-23

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


DESCRIPTION:
------------

This project contains some simple tools, instructions and Kickstart configuration files to assist with creating CentOS KVM virtual machines.

## Installation

The following guide assumes you have virtualization tools such as virt-install, libguestfs and virt-sparsify installed.

If you don't, then install them:

    yum groupinstall "Virtualization Tools"
    yum install virt-manager libvirt libvirt-python python-virtinst virt-top libguestfs-tools
    reboot

You must download this project for the unattended creation script to work correctly:

	git clone git://github.com/fubralimited/CentOS-KVM-Image-Tools.git


## Kickstart configuration scripts

The Kickstarts directory contains different Kickstart configuration files to create Virtual Machine images.

* The centos6x-vm-gpt-selinux.cfg is the Kickstart file to create a CentOS 64bit Virtual Machine guest.
* The centos6x-i386-vm-gpt-selinux.cfg is the Kickstart file to create a CentOS 32bit Virtual Machine guest.
* The centos6x-hypervisor-gpt-selinux.cfg is the Kickstart file to create a CentOS 64bit Virtual Machine hypervisor.

All the Kickstart files contain the following common packages. In addition all the Kickstart configuration files enable the SELinux and the firewall, and do not install the graphic environment X.

* @core
* @server-policy
* vim-enhanced
* nano
* aide

Note that by default we install the AIDE (Advanced Intrusion Detection Environment) package, a file and directory integrity checker.

The CentOS hypervisor Kickstart is the same as the 64bit version, but with the following additional packages included.

* kvm
* virt-manager
* libvirt
* libvirt-python
* python-virtinst
* virt-top
* libguestfs-tools

You can learn more about the specific contents of each file by viewing the comments in the files.

At this point you should note that the default password for the root user is changeme1122 (as defined on the Kickstart configuration file).


## The Creation Script

In the Centos KVM Image Tools project that you cloned form GitHub in the previous step you will find a scripts directory. Here you will find one called centoskvm.sh. This is the script you need to run to create the Master Image automatically.

When you run the script a virtual machine will be created with the given settings, and output from the installation will be sent to your terminal rather than a VNC session. This VM will then be compressed and an image will be created from it.

Run the script on the command line.

	sh centoskvm.sh centos_vm

Where centos_vm is the name of the virtual machine we want to create.

By default this script uses the centos6x-vm-gpt-selinux.cfg Kickstart configuration file. You can clone the project on GitHub and change the Kickstart file to change settings in the unattended creation.


### What’s on the inside?

The following section illustrates the main operations performed by the centoskvm.sh script to better understand the process and provide some tips.

####1. Creating the Virtual Machine

The firt step consist into creating the VM using the virt-install command with the following parameters:

	virt-install \
	--name centos_vm \
	--ram 512 \
	--cpu host \
	--vcpus 1 \
	--nographics \
	--os-type=linux \
	--os-variant=rhel6 \
	--location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
	--initrd-inject=../Kickstarts/centos6x-vm-gpt-selinux.cfg \
	--extra-args="ks=file:/centos6x-vm-gpt-selinux.cfg text console=tty0 utf8 console=ttyS0,115200" \
	--disk path=/var/lib/libvirt/images/centos_vm.qcow2,size=10,bus=virtio,format=qcow2 \
	--force \
	--noreboot

On the script the Kickstart configuration is a local file injected via the "initrd-inject" parameter. Is it also possible to pass the Kickstart file as URL:

	virt-install \
	--name centos_vm \
	--ram 512 \
	--cpu host \
	--vcpus 1 \
	--nographics \
	--os-type=linux \
	--os-variant=rhel6 \
	--location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
	--extra-args="ks=http://fubralimited.github.com/CentOS-KVM-Image-Tools/kickstarts/centos6x-vm-gpt-selinux.cfg text console=tty0 utf8 console=ttyS0,115200" \
	--disk path=/var/lib/libvirt/images/centos_vm.qcow2,size=10,bus=virtio,format=qcow2 \
	--force \
	--noreboot

The image created in this way has the default network settings (DHCP), it is fully updated and is not restarted. Please check the Kickstart configuration file source code for more information and options.

#### 2. Reset the Virtual Machine

The virt-sysprep command is used to reset and unconfigure the virtual machine so clones can be made. The VM is modified in place, so the guest must be shut down.

	cd /var/lib/libvirt/images/
	virt-sysprep --format=qcow2 --no-selinux-relabel -a centos_vm.qcow2

The –no-selinux-relabel option is set to avoid automatic SELinux relabeling at boot. Instead we relabel the VM manually on the next step.

#### 3. SElinux relabelling

Using the guestfish shell we can manually relabel the entire filesystem using the following options without the need to start the VM.

	guestfish --selinux -i centos_vm.qcow2 <<EOF
	sh load_policy
	sh 'restorecon -Rv /'
	EOF

or in one line:

	guestfish --selinux -i centos_vm.qcow2 <<<'sh "load_policy && restorecon -R -v /"'


#### 4. Make the virtual machine image sparse

Using the virt-sparsify tool we can make a virtual machine image sparse a.k.a. thin-provisioned. This means that free space within the disk image can be converted back to free space on the host.

	virt-sparsify --compress --convert qcow2 --format qcow2 centos_vm.qcow2 centos_vm-sparsified.qcow2


#### 5. Rename VM image file and set the correct ownership

On this last step we rename the VM image file and set the correct ownership.

	rm -rf centos_vm.qcow2
	mv centos_vm-sparsified.qcow2 centos_vm.qcow2
	chown qemu:qemu centos_vm.qcow2

Please check the centoskvm.sh script for further details and configurations.

As you may be able to see from the –disk parameter the completed and sparsified disk image will be exported to the local filesystem in qcow2 format.

You can now access and deploy nodes using this newly created CentOS image by accessing the file in this location.

	/var/lib/libvirt/images/centos_vm.qcow2

The virtual machine centos_vm created as above is shut down by default, so we can easily clone it and import to create new guests.


## The Resize Script

Assuming that we have a VM created as above, the resizevm.sh script allows us to expand it in place, resizing any partitions contained within.
All the steps are illustrated here so you can adapt the commands to your needs.

The resizevm.sh script accepts the VM name and the new size as command line parameters and resizes the virtual machine in place. For example:

	sh resizevm.sh centos_vm 20G

Where centos_vm is the name of the virtual machine we want to resize and 20G is the new size.
You can also resize relative to the current size of the disk image by using the + symbol:

	sh resizevm.sh centos_vm +10G

### What’s on the inside?

The following section illustrates the main operations performed by the resizevm.sh script to better understand the process and provide some tips.
We assume that centos_vm is the name of the virtual image we want resize.

#### 1. Shut the virtual machine down

The following operations and commands should not be used on live virtual machines, you must shut the virtual machine down before workig on it.

	virsh shutdown centos_vm

#### 2. Change directory

Now change to the images directory where we store the VM images.

	cd /var/lib/libvirt/images

#### 3. Clone VM image

To speedup the resizing process we start by creating a copy of the existing VM image file.
The resizing script contains an additional step to extract the VM image filename, since we already know the name of the image we can skip this step.

	cp -f centos_vm.qcow2 centos_vm_temp.qcow2

#### 4. Resize the cloned image

Now that we have cloned the image we can use the following qemu-img command to grow the image.

Please note that only images in raw format can be resized regardless of version. The Operating Systems based on Red Hat Enterprise Linux 6.1 and later adds the ability to grow (but not shrink) images in qcow2 format.

	qemu-img resize centos_vm_temp.qcow2 20G

Alternatively you can also resize relative to the current size of the disk image by using the + symbol prefixing the storage parameter:

	qemu-img resize centos_vm_temp.qcow2 +10G

#### 5. Resize the partitions

Using the virt-resize command we can resize a virtual machine image, making it larger or smaller overall, and resizing or deleting any partitions contained within.

Virt-resize cannot resize VM images in-place, so this is why we cloned and expanded the VM image in the previous steps.

Resize the old image to the new one expanding the volumes.

	virt-resize --expand /dev/vda2 --LV-expand /dev/vg_main/lv_root centos_vm.qcow2 centos_vm_temp.qcow2

This would first expand the partition (and PV), and then expand the root device to fill the extra space in the PV.

The “–expand” option, expands the Physical Volume (PV) /dev/vda2 to fill any extra space.
The /dev/vda2 is the name of the PV disk device as originally defined using the centoskvm.sh creation script.

The “–LV-expand” option expands the root device (/dev/vg_main/lv_root) to fill the extra space in the PV .

#### 6. Make a backup of the VM for any eventuality

At this point it may seem odd to make a backup half way through the process. In fact, this is because we have not actually edited the original image, we simply need to free up the name so that the new image can inherit the name of the original image.

	mv -f centos_vm.qcow2 centos_vm.backup.qcow2

#### 7. Sparsify image

Using the virt-sparsify tool we can make a virtual machine image sparse a.k.a. thin-provisioned. This means that free space within the disk image can be converted back to free space on the host.

	virt-sparsify --format qcow2 --compress centos_vm_temp.qcow2 centos_vm.qcow2

The centos_vm.qcow2 image is now the sparsified version of centos_vm_temp.qcow2, so we can safely remove the latter.

#### 8. Remove the resized image

	rm -f centos_vm_temp.qcow2

#### 9. Set file ownership

	chown qemu:qemu centos_vm.qcow2

#### 10. Restart the virtual machine

	virsh start centos_vm

#### 11. If the new image works fine, then we can delete the backup image

	rm -rf centos_vm.backup.qcow2



## Add a virtual storage device

An alternative way to add storage to an existing VM consist into creating a Virtual Storage device and attach it to the VM. 

For simplicity we assume that the VM image you wish to extend has been created using the centoskvm.sh shell script, as explained above.

The file-based virtual storage device acts as a virtualized hard drive for virtualized guests and its creation is quite quite straightforward.

### 1. Create the Virtual Storage device image

#### 1.1. Create the XML configuration file for the extra storage device

This XML file will be used to attach the storage to an existing VM. Firstly change to the images directory where your VM image should be.

	cd /var/lib/libvirt/images

Now create the empty XML file with your preferred editor, in this case I’m using nano.

	nano extra_storage.xml

Copy and paste the following example XML file into the one you have just created.

	<disk type='file' device='disk'>
		<driver name='qemu' type='qcow2' cache='none'/>
		<source file='/var/lib/libvirt/images/extra_storage.qcow2' />
		<target dev='vdb' bus='virtio'/>
		<alias name='virtio-disk-extra-storage'/>
	</disk>

Now make the following changes:

    Choose a name for the virtual storage image name we will create, in this case “extra_storage.qcow2″.
    Ensure you specify a device name (“vdb”) for the virtual block device attributes.
    Finally, give the new storage device an alias, in this case “virtio-disk-extra-storage”.

It is very important that the defined parameters inside the XML file are unique.

#### 1.2. Create an empty storage image with the desired size

The following command creates an empty 20GB storage image in qcow2 format. You can change the 20G to any size you require.

	qemu-img create -f qcow2 extra_storage.qcow2 20G

Please note that the file name should be the same as the one specified in the XML file.

#### 1.3. Set image file ownership

	chown qemu:qemu extra_storage.qcow2

#### 1.4. Attach the storage device to an existing Virtual Machine

Assuming that the virtual machine is named “centos_vm”. You can also see that in the following command we use the XML file from earlier in this article.

	virsh attach-device --persistent centos_vm extra_storage.xml

The “–persistent” option is added to be sure that this configuration does not get lost when you power off the virtual machine.

At this point the virtual device is attached and we can configure the logical device on the VM.

### 2. Configure the logical device

Start the Virtual machine if not started already and log into it, then:

#### 2.1. Label disk

In this step we set the partition table to the GPT type to support partitions greater than 2TB.
vdb is the target device as defined in the XML file.

	parted /dev/vdb mklabel gpt

#### 2.2. Resize the partition

We partition the new volume to the correct size, again using parted.

	parted /dev/vdb -s -a optimal mkpart primary 1 20G

Replace 20G with the partition size you require up to the limit defined in step 1.2.

#### 2.3. Align-check

Determine whether the starting sector of the first partition meets the disk’s selected alignment criteria.

	parted /dev/vdb align-check optimal 1

#### 2.4. Initialize the partition for use by Logical Volume Manager (LVM)

	pvcreate /dev/vdb1

#### 2.5. Create volume group

	vgcreate vg_name /dev/vdb1

#### 2.6. Create logical volume

	lvcreate -l 100%FREE -n lv_name /dev/vg_name

#### 2.7. Create an EXT4 filesystem

	mkfs.ext4 /dev/vg_name/lv_name

#### 2.8. Create mount point for the new storage

	mkdir -p /storage

#### 2.9. Add entry to fstab

	mount src=/dev/mapper/vg_name-lv_name name=/storage fstype=ext4 opts=defaults,noatime,nodiratime state=mounted

Finally run the "fdisk -l" command and you should see the newly created storage device attached to the VM:

	Disk /dev/vdb: 21.5 GB, 21474836480 bytes
	255 heads, 63 sectors/track, 2610 cylinders
	Units = cylinders of 16065 * 512 = 8225280 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk identifier: 0x00000000

	   Device Boot      Start         End      Blocks   Id  System
	/dev/vdb1               1        2611    20971519+  ee  GPT

	Disk /dev/mapper/vg_name-lv_name: 20.0 GB, 19994247168 bytes
	255 heads, 63 sectors/track, 2430 cylinders
	Units = cylinders of 16065 * 512 = 8225280 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk identifier: 0x00000000


## Useful commands

This section contains a short list of basic useful commands to play with Virtual Machines using virt-tools. For an extensive guide please consult Managing guests with virsh.

### List all available virtual machines

	virsh list --all

The “–all” option lists all domains, whether active or not. This will give you an output similar to the folowing:

	Id    Name                           State
	----------------------------------------------------
	 0    domain0                        running
	 1    centos_vm                      running
	 2    rheldomain                     running

### Start a virtual machine

	virsh start centos_vm

### Shutdown a virtual machine

	virsh shutdown centos_vm

### Connect to a virtual machine’s console

	virsh console centos_vm

To exit the console press CTRL + ]

### Completely delete the virtual machine

	virsh destroy centos_vm
	virsh undefine centos_vm
	rm /var/lib/libvirt/images/centos_vm.qcow2

* destroy – this forces the VM to shutdown. It will still appear in the virsh list in a shutdown state.
* undefine – this removes the VM from the hypervisor and prevents any further virsh commands being carried out on it.
* The final remove command deletes the virtual machine disk image from the hypervisor storage device.

## Creating a new guest using a copy of the Golden Master Image

This section shows how to create a new VM guest starting from an existing VM image.

### Copy the VM image

	cp centos_vm.qcow2 centos_vm_new.qcow2

Create a new guest using this image with virt-install –import

	virt-install \
	--name "centos_vm_new" \
	--cpu host \
	--vcpus 1 \
	--ram 1024 \
	--os-type=linux \
	--os-variant=rhel6 \
	--disk path=/var/lib/libvirt/images/centos_vm_new.qcow2 \
	--nographics \
	--force \
	--import

For other virt-install options please consult the virt-install manual.

## Create a new guest using the Golden Master as a backing image

Create a new image using qemu-img that specifies the master as the backing image

	cd /var/lib/libvirt/images/
	qemu-img create -f qcow2 -b centos_vm.qcow2 centos_vm_backed.qcow2

Create a new guest using this image with virt-install –import

	virt-install \
	--name "centos_vm_backed" \
	--cpu host \
	--vcpus 1 \
	--ram 1024 \
	--os-type=linux \
	--os-variant=rhel6 \
	--disk path=/var/lib/libvirt/images/centos_vm_backed.qcow2 \
	--nographics \
	--force \
	--import

## Adding VNC graphics

If you want to add a graphical VNC console to an existing guest that doesn’t currently have one set up, you can do so by editing the domain XML file and adding a graphics line. Any time you change the XML config, you need to run the virsh define command again.

Shutdown the guest

	virsh shutdown centos_vm

Edit the XML file

	vim /etc/libvirt/qemu/centos_vm.xml

Add the following line in the devices section

	<graphics type='vnc' port='-1' autoport='yes'/>

Import the updated guest XML configuration

	virsh define /etc/libvirt/qemu/centos_vm.xml

Start the guest

	virsh start centos_vm

Connect to the VNC graphical console

If you are connected over SSH, make sure you have X11 installed on your client machine, and that you connected with X11 forwarding enabled (e.g. ssh -x).

	virt-viewer centos_vm
