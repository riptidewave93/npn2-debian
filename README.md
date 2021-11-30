# npn2-debian

Build script to build a Debian 10 image for FriendlyARM NanoPi H5 based boards, as well as all dependencies. This includes the following:

- Mainline Linux Kernel - [linux-5.6.y](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/log/?h=linux-5.6.y)
  - RTL8189ES WiFi Driver - [master](https://github.com/jwrdegoede/rtl8189ES_linux/tree/master)
  - Wireguard Mainline
- Arm Trusted Firmware - [arm-trusted-firmware/master branch](https://github.com/ARM-software/arm-trusted-firmware/tree/master)
- Mainline U-Boot - [v2020.01](https://github.com/u-boot/u-boot/tree/v2020.01)

Note that there are patches/modifications applied to the kernel and u-boot. The changes made can be seen in the `./patches` and `./overlay` directories. Also, a `./downloads` directory is generated to store a copy of the toolchain during the first build.

## Supported Boards
Currently images for the following devices are generated:
* FriendlyARM NanoPi Neo2
* FriendlyARM NanoPi Neo2 v1.1
* FriendlyARM NanoPi Neo2 Black
* FriendlyARM NanoPi Neo Core2
* FriendlyARM NanoPi Neo Plus2
* FriendlyARM NanoPr R1S H5

## Requirements

- The following packages on your Debian/Ubuntu build host: `bc binfmt-support build-essential debootstrap device-tree-compiler dosfstools fakeroot git kpartx lvm2 parted python-dev python3-dev qemu qemu-user-static swig wget bison flex libssl-dev`

## Usage
- Just run `sudo ./build.sh`.
- Completed builds output to `./output`
- To cleanup and clear all builds, run `sudo ./build.sh clean`

## Flashing
- Take your completed image from `./output` and extract it with gunzip
- Flash directly to an SD card. Example: `dd if=./neo-core2*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`

## To Do
* Bring back kernel overlay support (hoping this gets mainlined for arm64)
* Get bluetooth working on the Plus2 board

## Notes
- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
- The Neo2 image will work on both version v1.0 and v1.1. The v1.1 image will only boot correctly on v1.1 boards, due to it supporting higher voltage CPU speeds. Running the v1.1 image on a v1.0 board WILL cause kernel panics during boot!
