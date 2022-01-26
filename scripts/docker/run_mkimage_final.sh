#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Tempdir for root
GENIMAGE_ROOT=$(mktemp -d)

# setup and move bits
mkdir -p ${build_path}/final
cp ${build_path}/boot.vfat ${build_path}/final/
cp ${build_path}/rootfs.ext4 ${build_path}/final/
cp ${root_path}/genimage_final.cfg ${build_path}/genimage.cfg

# Update UUID in genimage.cfg to match what u-boot has set
sed -i "s|PLACEHOLDERUUID|$(cat ${build_path}/disk-signature.txt)|g" ${build_path}/genimage.cfg

# We get to gen an image per board, YAY!
for board in "${supported_devices[@]}"; do
	echo "Generating disk image for ${board}"
	cp ${build_path}/uboot/${board}.uboot ${build_path}/final/u-boot.bin
	genimage                         \
		--rootpath "${GENIMAGE_ROOT}"     \
		--tmppath "/tmp/genimage-initial-tmppath"    \
		--inputpath "${build_path}/final"  \
		--outputpath "${build_path}/final" \
		--config "${build_path}/genimage.cfg"
	mv ${build_path}/final/sdcard.img ${build_path}/final/debian-${board}.img
	gzip ${build_path}/final/debian-${board}.img
	rm ${build_path}/final/u-boot.bin
	rm -rf /tmp/genimage-initial-tmppath # Cleanup for next run, or if we are done
done

# Cleanup
rm ${build_path}/final/boot.vfat ${build_path}/final/rootfs.ext4 ${build_path}/genimage.cfg ${build_path}/disk-signature.txt