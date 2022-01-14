#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Supported Devices
supported_devices=(sun50i-h5-nanopi-r1s-h5 sun50i-h5-nanopi-neo2 sun50i-h5-nanopi-neo-plus2)

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain_filename="$(basename $toolchain_url)"
toolchain_bin_path="${toolchain_filename%.tar.xz}/bin"
toolchain_cross_compile="aarch64-none-linux-gnu-"

# Arm Trusted Firmware
atf_src="https://github.com/ARM-software/arm-trusted-firmware/archive/refs/heads/master.zip"
atf_filename="arm-trusted-firmware-master.zip"
atf_platform="sun50i_a64"

# U-Boot
uboot_src="https://github.com/u-boot/u-boot/archive/refs/tags/v2022.01.zip"
uboot_filename="u-boot-2022.01.zip"
uboot_overlay_dir="u-boot"

# Kernel
kernel_src="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-5.15.y.tar.gz"
kernel_filename="linux-5.15.y.tar.gz"
kernel_config="nanopi_h5_defconfig" # Global config for all boards
kernel_overlay_dir="kernel"

# RTL8189ETV
rtl_src="https://github.com/jwrdegoede/rtl8189ES_linux/archive/refs/heads/master.zip"
rtl_filename="rtl8189ES_linux-master.zip"

# Distro
distrib_name="debian"
deb_mirror="https://mirrors.kernel.org/debian/"
deb_release="bullseye"
deb_arch="arm64"
fs_overlay_dir="filesystem"

debug_msg () {
    BLU='\033[0;32m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

error_msg () {
    BLU='\033[0;31m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}