#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
kernel_builddir=$(mktemp -d)
tar -xzf ${root_path}/downloads/${kernel_filename} -C ${kernel_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64

# Here we go
cd ${kernel_builddir}/${kernel_filename%.tar.gz}

# If we have patches, apply them
if [[ -d ${root_path}/patches/kernel/ ]]; then
    for file in ${root_path}/patches/kernel/*.patch; do
        echo "Applying kernel patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${kernel_overlay_dir}/ ]]; then
    echo "Applying ${kernel_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${kernel_overlay_dir}/* ./
fi

# Build as normal
make ${kernel_config}
make -j`getconf _NPROCESSORS_ONLN` deb-pkg dtbs

# Prep for storage of important bits
mkdir -p ${build_path}/kernel
for i in "${supported_devices[@]}"; do
	cp arch/arm64/boot/dts/allwinner/${i}.dtb ${build_path}/kernel
done
cp ${kernel_builddir}/linux-*.deb ${build_path}/kernel

# Now that we have done this, time to ALSO build RTL8189ETV since it relies on kernel src
rtl_builddir=$(mktemp -d)
unzip ${root_path}/downloads/${rtl_filename} -d ${rtl_builddir}

# here we go AGAIN!
cd ${rtl_builddir}/${rtl_filename%.zip}

# If we have patches, apply them
if [[ -d ${root_path}/patches/rtl8189es/ ]]; then
    for file in ${root_path}/patches/rtl8189es/*.patch; do
        echo "Applying rtl8189es patch ${file}"
        patch -p1 < ${file}
    done
fi

# Build the wifi driver
make KSRC="${kernel_builddir}/${kernel_filename%.tar.gz}"

# Copy our wifi drivers
cp *.ko ${build_path}/kernel