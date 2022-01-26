#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Generate random hex string for use with the final disk image, used for disk mapping later...
hexdump -n 4 -e '1 "0x%08X" 1 "\n"' /dev/urandom > ${build_path}/disk-signature.txt

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --foreign --arch=${deb_arch} ${deb_release} ${build_path}/rootfs ${deb_mirror}
cp /usr/bin/qemu-aarch64-static usr/bin/
chroot ${build_path}/rootfs mount -t proc proc /proc # THIS IS THE MAGIC!!!!!!
chroot ${build_path}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/${fs_overlay_dir}/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${root_path}/overlay/${fs_overlay_dir}/* ./
fi

# Apply our disk signature to boot.cmd
UBOOTUUID=$(cat ${build_path}/disk-signature.txt | awk '{print tolower($0)}')
sed -i "s|PLACEHOLDERUUID|${UBOOTUUID:2}|g" ./boot/boot.cmd

# Hostname
echo "${distrib_name}" > ${build_path}/rootfs/etc/hostname
echo "127.0.1.1	${distrib_name}" >> ${build_path}/rootfs/etc/host

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > ${build_path}/rootfs/debconf.set

# Copy over kernel goodies
cp -r ${build_path}/kernel ${build_path}/rootfs/root/

# Kick off bash setup script within chroot
cp ${docker_scripts_path}/bootstrap/001-bootstrap ${build_path}/rootfs/bootstrap
chroot ${build_path}/rootfs /bootstrap
rm ${build_path}/rootfs/bootstrap

# Final cleanup
rm ${build_path}/rootfs/usr/bin/qemu-aarch64-static