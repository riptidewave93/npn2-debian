#!/bin/bash

# Generate SSH keys & enable SSH
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -t rsa -N ""
ssh-keygen -f /etc/ssh/ssh_host_dsa_key -t dsa -N ""

systemctl enable ssh.service
systemctl start ssh.service

# Figure out which mmc we are on
bootedmmc=$(cat /proc/cmdline | sed 's| |\n|g' | sed -n 's/^root=//p')

# Resize root disk
fdisk ${bootedmmc%??} << DISK
d
2
n
p
2
n
w
DISK
partprobe
resize2fs ${bootedmmc%??}p2
sync

# Probe for any added modules
depmod -a

# Load in wireless if we are a R1S H5, and setup eth1
if grep -q "FriendlyARM NanoPi R1S H5" /proc/device-tree/model; then
  modprobe 8189es
  echo "8189es" >> /etc/modules
  echo "
allow-hotplug eth1
iface eth1 inet dhcp
iface eth1 inet6 dhcp" >> /etc/network/interfaces
fi

# Fixup initramfs for fsck on boot to workf
update-initramfs -u
rm /boot/initramfs.cpio.gz
KERN_VERSION=$(echo ${KMOD_PATH} | xargs basename )
mv /boot/initrd.img-${KERN_VERSION}* /boot/initramfs.cpio.gz

# Add our mount for boot and mount it
echo "${bootedmmc%??}p1  /boot           vfat    defaults        0       1" >> /etc/fstab
mount -a

# And were done!
systemctl disable first-boot.service
exit 0