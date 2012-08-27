# This example uses parted to create a GUID partition table (GPT), which allows for > 2TB partitions, unlike the standard fdisk based partitions that anaconda uses.
# The important parts are 1) parted command must go in pre 2) you must have clearpart --none, otherwise it wipes the GPT partition table! If writing your own kickstart, double check your kickstart file to make sure there are not multiple clearparts.
auth  --useshadow  --enablemd5
bootloader --location=mbr
cmdline
firewall --enabled
firstboot --disable
keyboard uk
lang en_GB
rootpw changeme1122
selinux --disabled
skipx
timezone  Europe/London
install
reboot

url --url=http://mirror.catn.com/pub/centos/6/os/x86_64
repo --name="CATN Centos Repo" --baseurl=http://mirror.catn.com/pub/centos/6/os/x86_64
network --bootproto=dhcp --hostname=test-centos6-gpt3 --device=eth0 --onboot=on

# Clear the Master Boot Record
zerombr

# Setup simple KVM partition scheme
# Important to run clearpart --none otherwise it will wipe the gpt label
clearpart --none
part /boot --fstype=ext4 --size=500
part pv.00 --grow --asprimary --size=1

# Increased pesize from 4096 KB to 262144 KB (0.25GB) to allow bigger logvols
volgroup vg_main --pesize=262144 pv.00
logvol swap --name=lv_swap --vgname=vg_main --size=256
logvol / --fstype=ext4 --name=lv_root --vgname=vg_main --size=4096
logvol /var/lib/libvirt --fstype=ext4 --name=lv_libvirt --vgname=vg_main --size=1 --grow 

%pre
parted -s /dev/vda mklabel gpt

%packages –nobase
@core
@server-policy
vim-enhanced

%post
%end