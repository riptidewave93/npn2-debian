#!/bin/bash

# Generate new SSH keys for the host
ssh-keygen -q -f "/etc/ssh/ssh_host_rsa_key" -N '' -t rsa
ssh-keygen -q -f "/etc/ssh/ssh_host_dsa_key" -N '' -t dsa
ssh-keygen -q -f "/etc/ssh/ssh_host_ecdsa_key" -N '' -t ecdsa
ssh-keygen -q -f "/etc/ssh/ssh_host_ed25519_key" -N '' -t ed25519

# Get our partuuid so we can map what MMC we are on
rootpartuuid=$(cat /proc/cmdline | sed 's| |\n|g' | sed -n 's/^root=PARTUUID=//p')

# For every MMC disk we have, get our Disk Identifier
for mmc in $(ls /dev/mmcblk[00-99]); do
  if [[ "$(fdisk -l ${mmc} | grep "Disk identifier:" | awk '{print $3}')" == "0x${rootpartuuid%???}" ]]; then
    bootedmmc="${mmc}p2"
    break
  fi
done

# If we didn't find our disk, bomb out!
if [ -z ${bootedmmc+x} ]; then
  echo "ERROR, unable to determine root mmc partition! Skipping resize..."
else
  # Get start offset of rootfs partition
  rootfs_start=$(fdisk -l ${bootedmmc%??} | grep ${bootedmmc} | awk '{ print $2 }')

  # Resize root disk
  fdisk ${bootedmmc%??} << DISK
d
2
n
p
2
${rootfs_start}

n
w
DISK

  # Add our mount for boot and mount it
  echo "PARTUUID=${rootpartuuid%??}01  /boot           vfat    defaults        0       1" >> /etc/fstab
  mount -a

  # Update kernel partition mapping & kickoff resize
  partprobe
  resize2fs ${bootedmmc%??}p2
  sync
fi

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

# Fixup initramfs for fsck on boot to work
KERN_VERSION=$(find /lib/modules/ -maxdepth 1 | sort | tail -1 | xargs basename )
update-initramfs -u -k ${KERN_VERSION}
rm /boot/initramfs.cpio.gz
mv /boot/initrd.img-${KERN_VERSION}* /boot/initramfs.cpio.gz

# And were done!
systemctl disable first-boot.service
rm -f /etc/systemd/system/first-boot.service
rm -f $0