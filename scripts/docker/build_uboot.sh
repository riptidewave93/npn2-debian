#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
uboot_builddir=$(mktemp -d)
unzip -q ${root_path}/downloads/${uboot_filename} -d ${uboot_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64
export BL31=${build_path}/atf/bl31.bin

# Here we go
cd ${uboot_builddir}/${uboot_filename%.zip}

# If we have patches, apply them
if [[ -d ${root_path}/patches/u-boot/ ]]; then
    for file in ${root_path}/patches/u-boot/*.patch; do
        echo "Applying u-boot patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${uboot_overlay_dir}/ ]]; then
    echo "Applying ${uboot_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${uboot_overlay_dir}/* ./
fi

# Each board gets it's own u-boot, so build each at a time
mkdir -p ${build_path}/uboot
for board in "${supported_devices[@]}"; do
    cfg=$board
    cfg+="_defconfig"
    make distclean
    make $cfg
    make -j`getconf _NPROCESSORS_ONLN`
    mv u-boot-sunxi-with-spl.bin ${build_path}/uboot/$board.uboot
done
