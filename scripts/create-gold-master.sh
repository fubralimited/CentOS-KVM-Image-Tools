#!/bin/bash

# Ensure script is being run as root
if [ `whoami` != root ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

read -p "***** Warning! ****** 
This script will remove all MAC address and hostname references from network scripts, and reset the SSH host keys and DHCP lease history. 
Do you wish to continue? " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Remove hostname references...
    sed -i '/HOSTNAME/d' /etc/sysconfig/network
    sed -i '/HOSTNAME/d' etc/sysconfig/network-scripts/ifcfg-eth0
    rm /etc/hostname
    yum clean all
    # Remove all mac address references
    rm /etc/udev/rules.d/70-persistent-net.rules
    sed -i '/HWADDR/d' etc/sysconfig/network-scripts/ifcfg-eth0
    # Remove the dhcp lease history
    rm -f /var/lib/dhclient/dhclient-eth0.leases
    # Remove the SSH Host keys etc...
    rm -f /etc/ssh/ssh_host_*
    rm -f /root/.ssh/known_hosts
fi