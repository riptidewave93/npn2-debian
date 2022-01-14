#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 02_download_dependencies.sh"

# Make sure our BuildEnv dir exists
if [ ! -d ${root_path}/downloads ]; then
    mkdir ${root_path}/downloads
fi

# Toolchain
if [ ! -f ${root_path}/downloads/${toolchain_filename} ]; then
    debug_msg "Downloading toolchain..."
    wget ${toolchain_url} -P ${root_path}/downloads
fi

# ATF
if [ ! -f ${root_path}/downloads/${atf_filename} ]; then
    debug_msg "Downloading Arm Trusted Firmware..."
    wget ${atf_src} -O ${root_path}/downloads/${atf_filename}
fi

# U-Boot
if [ ! -f ${root_path}/downloads/${uboot_filename} ]; then
    debug_msg "Downloading U-Boot..."
    wget ${uboot_src} -O ${root_path}/downloads/${uboot_filename}
fi

# Kernel
if [ ! -f ${root_path}/downloads/${kernel_filename} ]; then
    debug_msg "Downloading Kernel..."
    wget ${kernel_src} -O ${root_path}/downloads/${kernel_filename}
fi

# RTL8189ETV
if [ ! -f ${root_path}/downloads/${rtl_filename} ]; then
    debug_msg "Downloading RTL8189ETV..."
    wget ${rtl_src} -O ${root_path}/downloads/${rtl_filename}
fi

debug_msg "Finished 02_download_dependencies.sh"
