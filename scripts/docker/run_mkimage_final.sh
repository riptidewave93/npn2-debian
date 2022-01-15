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

# We get to gen an image per board, YAY!
for board in "${supported_devices[@]}"; do
	echo "Generating disk image for ${board}"
	cp ${build_path}/uboot/${board}.uboot ${build_path}/final/u-boot.bin
	genimage                         \
		--rootpath "${GENIMAGE_ROOT}"     \
		--tmppath "/tmp/genimage-initial-tmppath"    \
		--inputpath "/repo/BuildEnv/final"  \
		--outputpath "/repo/BuildEnv/final" \
		--config "/repo/genimage_final.cfg"
	mv ${build_path}/final/sdcard.img ${build_path}/final/debian-${board}.img
	gzip ${build_path}/final/debian-${board}.img
	rm ${build_path}/final/u-boot.bin
	rm -rf /tmp/genimage-initial-tmppath # Cleanup for next run, or if we are done
done

# Cleanup
rm ${build_path}/final/boot.vfat ${build_path}/final/rootfs.ext4