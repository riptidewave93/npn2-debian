#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
crust_builddir=$(mktemp -d)
unzip -q ${root_path}/downloads/${crust_filename} -d ${crust_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=or1k-elf- # Static based on deb package

# Here we go
cd ${crust_builddir}/${crust_filename%.zip}

# If we have patches, apply them
if [[ -d ${root_path}/patches/crust/ ]]; then
    for file in ${root_path}/patches/crust/*.patch; do
        echo "Applying crust patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${crust_overlay_dir}/ ]]; then
    echo "Applying ${crust_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${crust_overlay_dir}/* ./
fi

# Each board gets it's own u-boot, so build each at a time
mkdir -p ${build_path}/crust
for board in "${supported_devices[@]}"; do
    cfg=${board}
    cfg+="_defconfig"
    make distclean
    make ${cfg}
    make -j`getconf _NPROCESSORS_ONLN` scp
    mv ./build/scp/scp.bin ${build_path}/crust/${board}-scp.bin
done
