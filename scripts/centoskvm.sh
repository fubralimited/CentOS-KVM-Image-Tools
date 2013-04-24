#!/bin/sh

#==============================================================================+
# File name   : centoskvm.sh
# Begin       : 2013-04-18
# Last Update : 2013-04-23
# Version     : 1.0.0
#
# Description : Shell script used to generate a CentOS Virtual Machine image.
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
# sh centoskvm.sh centos-gold-master

# ensure script is being run as root
if [ `whoami` != root ]; then
   echo "ERROR: This script must be run as root" 1>&2
   exit 1
fi

# check for image name
if [ -z "$1" ]; then
	echo "ERROR: No argument supplied. Please provide the image name."
	exit 1
fi

# name of the image
IMGNAME=$1

# default kickstart file
KICKSTART="centos6x-vm-gpt-selinux.cfg"

# VM image file extension
EXT="qcow2"

echo "Generating VM ..."

# create image file
virt-install \
--name $IMGNAME \
--ram 512 \
--cpu host \
--vcpus 1 \
--nographics \
--os-type=linux \
--os-variant=rhel6 \
--location=http://mirror.catn.com/pub/centos/6/os/x86_64 \
--initrd-inject=../kickstarts/$KICKSTART \
--extra-args="ks=file:/$KICKSTART text console=tty0 utf8 console=ttyS0,115200" \
--disk path=/var/lib/libvirt/images/$IMGNAME.$EXT,size=10,bus=virtio,format=qcow2 \
--force \
--noreboot 

# change directory
cd /var/lib/libvirt/images/

# reset, unconfigure a virtual machine so clones can be made
virt-sysprep -a $IMGNAME.$EXT

# SELinux: relabelling all filesystem
guestfish --selinux -i $IMGNAME.$EXT <<EOF
sh load_policy
sh 'restorecon -Rv /'
EOF

# make a virtual machine disk sparse
virt-sparsify --format qcow2 --compress $IMGNAME.$EXT $IMGNAME-sparsified.$EXT

# remove original image
rm -rf $IMGNAME.$EXT

# rename sparsified 
mv $IMGNAME-sparsified.$EXT $IMGNAME.$EXT

# set correct ownership for the VM image file
chown qemu:qemu $IMGNAME.$EXT

echo "Process Completed. Use the 'virt start $IMGNAME' command to start the newly created VM."

#==============================================================================+
# END OF FILE
#==============================================================================+
