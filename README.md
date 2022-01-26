# npn2-debian

Build script to build a Debian 11 image for FriendlyARM NanoPi H5 based boards, as well as all dependencies. This includes the following:

- Mainline Linux Kernel - [linux-5.15.y](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/log/?h=linux-5.15.y)
  - RTL8189ES WiFi Driver - [master](https://github.com/jwrdegoede/rtl8189ES_linux/tree/master)
  - Wireguard Mainline
- Arm Trusted Firmware - [arm-trusted-firmware/master branch](https://github.com/ARM-software/arm-trusted-firmware/tree/master)
- Mainline U-Boot - [v2022.01](https://github.com/u-boot/u-boot/tree/v2022.01)

Note that there are patches/modifications applied to the kernel and u-boot. The changes made can be seen in the `./patches` and `./overlay` directories. Also, a `./downloads` directory is generated to store a copy of the toolchain during the first build.

## Supported Boards
Currently images for the following devices are generated:
* FriendlyARM NanoPi Neo2 (v1.0 and v1.1)
* FriendlyARM NanoPi Neo Plus2
* FriendlyARM NanoPr R1S H5

## Unsupported Boards
Below are boards that USED to be supported but currently are not. This is due to the lack of official upstream support, and the amount of maintaining they have required. PRs are welcome to bring them back.
* FriendlyARM NanoPi Neo2 Black
* FriendlyARM NanoPi Neo Core2

## Requirements

- The following packages below are required to use this build script. Note that this repo uses a Dockerfile to handle most of the heavy lifting, but some system requirements still exist.

`docker-ce losetup wget sudo make qemu-user-static`

Note that without qemu-user-static, debootstrap will fail!

## Usage
- Just run `make`.
- Completed builds output to `./output`
- To cleanup and clear all builds, run `make clean`

Other helpful commands:

- Have a build fail and have stale mounts? `make mountclean`
- Want to delete the download cache and do a 100% fresh build? `make distclean`

## Flashing
- Take your completed image from `./output` and extract it with gunzip
- Flash directly to an SD card. Example: `dd if=./neo-core2*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`

## To Do
* Bring back kernel overlay support (hoping this gets mainlined for arm64)
* Get bluetooth working on the Plus2 board
* Bring back other NanoPi H5 boards

## Notes
- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
- The Neo2 image will work on both version v1.0 and v1.1. Note that for compatibility reasons, the V1.1 will ONLY run at CPU clock speeds supported via the v1.0 board.