#!/bin/sh

#==============================================================================+
# File name   : resizevm.sh
# Begin       : 2013-04-18
# Last Update : 2013-04-23
# Version     : 1.0.0
#
# Description : Shell script used to resize Virtual Machine image.
#
# Website     : https://github.com/fubralimited/CentOS-KVM-Image-Tools
#
# Author: Nicola Asuni
#
# (c) Copyright:
#               Fubra Limited
#               Manor Coach House
#               Church Hill
#               Aldershot
#               Hampshire
#               GU12 4RQ
#               UK
#               http://www.fubra.com
#               support@fubra.com
#
# License:
#    Copyright (C) 2012-2013 Fubra Limited
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    See LICENSE.TXT file for more information.
#==============================================================================+

# USAGE EXAMPLE:
# sh resizevm.sh VM_NAME VM_SIZE
# sh resizevm.sh centosvm 20G

# NOTE: This script assume that the VM images are created using the centoskvm.sh
#       script and located at /var/lib/libvirt/images

# ensure script is being run as root
if [ `whoami` != root ]; then
   echo "ERROR: This script must be run as root" 1>&2
   exit 1
fi

# check for vm name
if [ -z "$1" ]; then
	echo "ERROR: No argument supplied. Please provide the Virtual machine name."
	exit 1
fi

# name of the image
VMNAME=$1

# check for new size
if [ -z "$2" ]; then
	echo "ERROR: Missing size argument. Please provide the Virtual machine name new size."
	exit 1
fi

echo "Resizing VM ..."

# name of the image
VMSIZE=$2

# extract VM file name
VMFILE=$(virsh dumpxml $VMNAME | grep "<source file='" | sed "s/[\t ]*<source file='\/var\/lib\/libvirt\/images\///" | sed "s/'\/>//")

# shut the virtual machine down
virsh shutdown $VMNAME

# change directory
cd /var/lib/libvirt/images

# clone VM image
cp -f $VMFILE $VMFILE.tmp

# resize the cloned image (i.e. 20 GB)
qemu-img resize $VMFILE.tmp $VMSIZE

# resize the partitions
virt-resize --expand /dev/vda2 --LV-expand /dev/vg_main/lv_root $VMFILE $VMFILE.tmp

# make a backup of the VM for any evenience:
mv -f $VMFILE $VMFILE.backup

# sparsify image
virt-sparsify --format qcow2 --compress $VMFILE.tmp $VMFILE

# remove the resized image
rm -f $VMFILE.tmp

# set file ownership
chown qemu:qemu $VMFILE

# restart the virtual machine
virsh start $VMNAME

# if the new image works fine, then we can delete the backup image:
#rm -rf $VMFILE.backup

echo "Process Completed. Please try the new image and delete the backup file if everything is OK."

#==============================================================================+
# END OF FILE
#==============================================================================+
