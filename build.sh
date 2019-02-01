#!/bin/bash

# Supported boards
supported_devices=(sun50i-h5-nanopi-neo2 sun50i-h5-nanopi-neo-core2 sun50i-h5-nanopi-neo-plus2)

# Date format, used in the image file name
mydate=`date +%Y%m%d-%H%M`

# Size of the image and boot partitions
imgsize="2G"
bootsize="100M"

# Location of the build environment, where the image will be mounted during build
ourpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
buildenv="$ourpath/BuildEnv"

# folders in the buildenv to be mounted, one for rootfs, one for /boot
# Recommend that you don't change these!
rootfs="${buildenv}/rootfs"
bootfs="${rootfs}/boot"

# Compiler settings
linaro_release="7.3-2018.05"
linaro_full_version="7.3.1-2018.05"

# Arm Trusted Firmware settings
atf_repo="https://github.com/ARM-software/arm-trusted-firmware.git"
atf_branch="master"
atf_platform="sun50i_a64"

# U-Boot settings
uboot_repo="https://github.com/u-boot/u-boot.git"
uboot_branch="v2019.01"
uboot_overlay_dir="u-boot"

# Kernel settings
kernel_repo="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
kernel_branch="linux-4.20.y"
kernel_config="nanopi_h5_defconfig" # Global config for all boards
kernel_overlay_dir="kernel"

# Distro settings
distrib_name="debian"
deb_mirror="https://mirrors.kernel.org/debian/"
deb_release="stretch"
deb_arch="arm64"
fs_overlay_dir="filesystem"

##############################
# No need to edit under this #
##############################

# Basic function we use to make sure we did not fail
runtest() {
  if [ $1 -ne 0 ]; then
    echo "Build Failed!"
	rm -rf "$ourpath/BuildEnv" "$ourpath/.build" "$ourpath/requires" "$ourpath/output"
    exit 1
  fi
}

# Check to make sure this is ran by root
if [ $EUID -ne 0 ]; then
  echo "DEB-BUILDER: this tool must be run as root"
  exit 1
fi

# Are we asking for a clean? If so, reset the env
if [[ "$1" == "clean" ]]; then
  echo "DEB-BUILDER: Cleaning build environment..."
  rm -rf "$ourpath/BuildEnv" "$ourpath/.build" "$ourpath/requires" "$ourpath/output"
  echo "DEB-BUILDER: Cleaning complete!"
  exit 0
fi

# make sure no builds are in process (which should never be an issue)
if [ -e ./.build ]; then
	echo "DEB-BUILDER: Build already in process, aborting"
	exit 1
else
	touch ./.build
fi

echo "DEB-BUILDER: Building $distrib_name Image"

# Start by making our build dir
mkdir -p $buildenv/toolchain
cd $buildenv

# Setup our build toolchain for this
echo "DEB-BUILDER: Setting up Toolchain"
if [ ! -e $ourpath/downloads/gcc-linaro-$linaro_full_version-x86_64_aarch64-linux-gnu.tar.xz ]; then
	mkdir $ourpath/downloads
	wget https://releases.linaro.org/components/toolchain/binaries/$linaro_release/aarch64-linux-gnu/gcc-linaro-$linaro_full_version-x86_64_aarch64-linux-gnu.tar.xz -P $ourpath/downloads
fi
tar xf $ourpath/downloads/gcc-linaro-$linaro_full_version-x86_64_aarch64-linux-gnu.tar.xz -C $buildenv/toolchain
export PATH=$buildenv/toolchain/gcc-linaro-$linaro_full_version-x86_64_aarch64-linux-gnu/bin:$PATH
export GCC_COLORS=auto
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# Build our dependencies
echo "DEB-BUILDER: Building Dependencies"
mkdir -p $ourpath/requires
mkdir -p $buildenv/git
cd $buildenv/git

# Build ARM Trusted Firmware
git clone $atf_repo --depth 1 -b $atf_branch
cd arm-trusted-firmware
make PLAT=$atf_platform bl31
runtest $?
export BL31=$buildenv/git/arm-trusted-firmware/build/$atf_platform/release/bl31.bin
cd $buildenv/git

# Build U-Boot
git clone $uboot_repo --depth 1 -b $uboot_branch ./u-boot
cd u-boot
# If we have patches, apply them
if [[ -d $ourpath/patches/u-boot/ ]]; then
	for file in $ourpath/patches/u-boot/*.patch; do
		echo "Applying u-boot patch $file"
		git am $file
    runtest $?
	done
fi
# Apply overlay if it exists
if [[ -d $ourpath/overlay/$uboot_overlay_dir/ ]]; then
	echo "Applying $uboot_overlay_dir overlay"
	cp -R $ourpath/overlay/$uboot_overlay_dir/* ./
fi
# Each board gets it's own u-boot, so build each at a time
for board in "${supported_devices[@]}"; do
	cfg=$board
	cfg+="_defconfig"
	make distclean
	make $cfg
	make -j`getconf _NPROCESSORS_ONLN`
  runtest $?
	touch $ourpath/requires/$board.uboot
	dd if=spl/sunxi-spl.bin of=$ourpath/requires/$board.uboot bs=8k
	dd if=u-boot.itb of=$ourpath/requires/$board.uboot bs=8k seek=4
done
cd $buildenv/git

# Build the Linux Kernel
mkdir linux-build && cd ./linux-build
git clone $kernel_repo --depth 1 -b $kernel_branch ./linux
cd linux
# If we have patches, apply them
if [[ -d $ourpath/patches/kernel/ ]]; then
	for file in $ourpath/patches/kernel/*.patch; do
		echo "Applying kernel patch $file"
		git am $file
    runtest $?
	done
fi
# Apply overlay if it exists
if [[ -d $ourpath/overlay/$kernel_overlay_dir/ ]]; then
	echo "Applying $kernel_overlay_dir overlay"
	cp -R $ourpath/overlay/$kernel_overlay_dir/* ./
fi
make $kernel_config
make -j`getconf _NPROCESSORS_ONLN` deb-pkg dtbs
runtest $?
for i in "${supported_devices[@]}"; do
	cp arch/arm64/boot/dts/allwinner/$i.dtb $ourpath/requires/
done
cd ../
cp linux-*.deb $ourpath/requires/
cd $buildenv

# Before we start up, make sure our required files exist
for file in "${supported_devices[@]}"; do
	if [[ ! -e "$ourpath/requires/$file.dtb" ]]; then
		echo "DEB-BUILDER: Error, required file './requires/$file.dtb' is missing!"
		rm $ourpath/.build
		exit 1
	fi
	if [[ ! -e "$ourpath/requires/$file.uboot" ]]; then
		echo "DEB-BUILDER: Error, required file './requires/$file.uboot' is missing!"
		rm $ourpath/.build
		exit 1
	fi
done

# Create the buildenv folder, and image file
echo "DEB-BUILDER: Creating Image file"
image="${buildenv}/headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img"
fallocate -l $imgsize "$image"
device=`losetup -f --show $image`
echo "DEB-BUILDER: Image $image created and mounted as $device"

# Format the image file partitions
echo "DEB-BUILDER: Setting up MBR/Partitions"
fdisk $device << EOF
o
n
p
1

+$bootsize
t
c
a
n
p
2


w
EOF

# Some systems need partprobe to run before we can fdisk the device
partprobe

# Mount the loopback device so we can modify the image, format the partitions, and mount/cd into rootfs
device=`kpartx -va $image | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
sleep 1 # Without this, we sometimes miss the mapper device!
device="/dev/mapper/${device}"
bootp=${device}p1
rootp=${device}p2
echo "DEB-BUILDER: Formatting Partitions"
mkfs.vfat $bootp -n BOOT
mkfs.ext4 $rootp -L root
mkdir -p $rootfs
mount $rootp $rootfs
cd $rootfs

#  start the debootstrap of the system
echo "DEB-BUILDER: Mounted partitions, debootstraping..."
debootstrap --no-check-gpg --foreign --arch $deb_arch $deb_release $rootfs $deb_mirror
cp /usr/bin/qemu-aarch64-static usr/bin/
LANG=C chroot $rootfs /debootstrap/debootstrap --second-stage

# Mount the boot partition
mount -t vfat $bootp $bootfs

# Now that things are mounted, copy over an overlay if it exists
if [[ -d $ourpath/overlay/$fs_overlay_dir/ ]]; then
	echo "Applying $fs_overlay_dir overlay"
	cp -R $ourpath/overlay/$fs_overlay_dir/* ./
fi

# Start adding content to the system files
echo "DEB-BUILDER: Setting up device specific tweaks"

# apt mirrors
echo "deb $deb_mirror $deb_release main contrib non-free
deb-src $deb_mirror $deb_release main contrib non-free" > etc/apt/sources.list

# Mounts
echo "proc            /proc           proc    defaults        0       0" > etc/fstab

# Hostname
echo "${distrib_name}" > etc/hostname
echo "127.0.1.1	${distrib_name}" >> etc/host

# Networking
echo "auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
iface eth0 inet6 dhcp
" > etc/network/interfaces

# uboot env tools
echo "
# MTD device name       Device offset   Env. size       Flash sector size
/boot/uboot.env         0x0             0x20000         0x2000
" > etc/fw_env.config

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > debconf.set

# Third Stage Setup Script (most of the setup process)
cat << EOF > third-stage
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections /debconf.set
rm -f /debconf.set
apt-get update
apt-get -y install git-core binutils ca-certificates e2fsprogs ntp parted curl \
locales console-common openssh-server less vim net-tools initramfs-tools \
u-boot-tools
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
echo "root:debian" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
sed -i 's|#PermitRootLogin prohibit-password|PermitRootLogin yes|g' /etc/ssh/sshd_config
echo 'HWCLOCKACCESS=yes' >> /etc/default/hwclock
echo 'RAMTMP=yes' >> /etc/default/tmpfs
apt-get install -y wireless-tools wpasupplicant firmware-brcm80211 wireless-regdb crda firmware-realtek bluez bluez-tools
git clone https://github.com/mirsys/fw_ap6212.git /lib/firmware/ap6212
rm -rf /lib/firmware/ap6212/.git
ln -s /lib/firmware/ap6212/fw_bcm43438a0.bin /lib/firmware/brcm/brcmfmac43430-sdio.bin
ln -s /lib/firmware/ap6212/nvram_ap6212.txt /lib/firmware/brcm/brcmfmac43430-sdio.txt
ln -s /lib/firmware/ap6212/fw_bcm43438a1.bin /lib/firmware/brcm/brcmfmac43430a1-sdio.bin
ln -s /lib/firmware/ap6212/nvram_ap6212a.txt /lib/firmware/brcm/brcmfmac43430a1-sdio.txt
rm -f third-stage
EOF
chmod +x third-stage
LANG=C chroot $rootfs /third-stage

# Setup our boot partition so we can actually boot
# we also need to do some kernel moving n shit due to discrepencies in stuff
cp -R $ourpath/requires root
cat << EOF > forth-stage
#!/bin/bash
dpkg -i /root/requires/linux-*.deb
mkdir -p /boot/allwinner
mv /root/requires/*.dtb /boot/allwinner/
mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
mv /boot/vmlinuz-* /boot/Image.gz
gunzip /boot/Image.gz
rm -rf /root/requires
cp /boot/initrd.img-* /boot/initramfs.cpio.gz
rm -f forth-stage
EOF
chmod +x forth-stage
LANG=C chroot $rootfs /forth-stage


echo "DEB-BUILDER: Cleaning up build space/image"

# Cleanup Script
echo "#!/bin/bash
update-rc.d ssh remove
apt-get autoclean
apt-get --purge -y autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
service ntp stop
rm -rf /boot.bak
rm -f cleanup
" > cleanup
chmod +x cleanup
LANG=C chroot $rootfs /cleanup

# startup script to generate new ssh host keys
rm -f etc/ssh/ssh_host_*
echo "DEB-BUILDER: Deleted SSH Host Keys. Will re-generate at first boot by user"
cat << EOF > etc/init.d/first_boot
#!/bin/bash
### BEGIN INIT INFO
# Provides:          first_boot
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Generates new ssh host keys on first boot & resizes rootfs
# Description:       Generates new ssh host keys on first boot & resizes rootfs
### END INIT INFO

# Generate SSH keys & enable SSH
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -t rsa -N ""
ssh-keygen -f /etc/ssh/ssh_host_dsa_key -t dsa -N ""
service ssh start
update-rc.d ssh defaults

# Figure out which mmc we are on
bootedmmc=\$(cat /proc/cmdline | sed 's| |\n|g' | sed -n 's/^root=//p')

# Resize root disk
fdisk \${bootedmmc%??} << LEL
d
2

n
p
2


n

w
LEL
partprobe
resize2fs \${bootedmmc%??}p2
sync

# Fixup initramfs for fsck on boot to work
update-initramfs -u
rm /boot/initramfs.cpio.gz
mv /boot/initrd.img-* /boot/initramfs.cpio.gz

# Add our mount for boot and mount it
echo "\${bootedmmc%??}p1  /boot           vfat    defaults        0       1" >> /etc/fstab
mount -a

# Cleanup
update-rc.d first_boot remove
rm -f \$0
EOF
chmod a+x etc/init.d/first_boot
LANG=C chroot $rootfs update-rc.d first_boot defaults
LANG=C chroot $rootfs update-rc.d first_boot enable

# Lets cd back
cd $buildenv && cd ..

# Unmount some partitions
echo "DEB-BUILDER: Unmounting Partitions"
umount $bootp
umount $rootp
kpartx -d $image

# Properly terminate the loopback devices
echo "DEB-BUILDER: Finished making the image $image"
dmsetup remove_all
losetup -D

# For each board, generate our images
echo "DEB-BUILDER: Copying image per board and installing u-boot"
savedir="$ourpath/output/$mydate"
mkdir -p $savedir
mv ${image} $savedir/headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img
for board in "${supported_devices[@]}"; do
	ShortName="$(echo $board | cut -f4-5 -d "-")"
	cp $savedir/headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img $savedir/${ShortName}_headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img
	# Install OUR u-boot
	dd if=$ourpath/requires/$board.uboot of=$savedir/${ShortName}_headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img bs=8k seek=1 conv=notrunc
	# Compress the specific image
	gzip $savedir/${ShortName}_headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img
done

# Move image out of builddir, as buildscript will delete it
echo "DEB-BUILDER: Moving things around"
mkdir -p $savedir/kernel
mv $ourpath/requires/linux-*.deb $savedir/kernel
mv $ourpath/requires/*.dtb $savedir/kernel
mkdir -p $savedir/u-boot
mv $ourpath/requires/*.uboot $savedir/u-boot
cd $ourpath

echo "DEB-BUILDER: Cleaning Up"
rm $savedir/headless_${distrib_name}_${deb_release}_${deb_arch}_${mydate}.img
rm $ourpath/.build
rm -r $ourpath/requires
rm -r $buildenv
echo "DEB-BUILDER: Finished!"
exit 0
