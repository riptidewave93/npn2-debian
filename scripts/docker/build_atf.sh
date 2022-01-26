#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
atf_builddir=$(mktemp -d)
unzip -q ${root_path}/downloads/${atf_filename} -d ${atf_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64

# cd to said new builddir
cd ${atf_builddir}/${atf_filename%.zip}
make LOG_LEVEL=10 PLAT=${atf_platform} bl31
mkdir -p ${build_path}/atf
mv ./build/${atf_platform}/release/bl31.bin ${build_path}/atf