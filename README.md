# npn2-debian

Build script to build a Debian 9 image for FriendlyARM NanoPi H5 based boards, as well as all dependencies. This includes the following:

- Mainline Linux Kernel - [v4.20.y](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/log/?h=linux-4.20.y)
- Arm Trusted Firmware - [arm-trusted-firmware/master branch](https://github.com/ARM-software/arm-trusted-firmware/tree/master)
- Mainline U-Boot - [v2019.01](https://github.com/u-boot/u-boot/tree/v2019.01)

Note that there are patches/modifications applied to the kernel and u-boot. The changes made can be seen in the `./patches` and `./overlay` directories. Also, a `./downloads` directory is generated to store a copy of the toolchain during the first build.

## Supported Boards
Currently images for the following devices are generated:
* FriendlyARM NanoPi Neo2
* FriendlyARM NanoPi Neo Core2
* FriendlyARM NanoPi Neo Plus2

## Requirements

- The following packages on your build host: `bc binfmt-support build-essential debootstrap device-tree-compiler dosfstools fakeroot git kpartx lvm2 parted python-dev python3-dev qemu qemu-user-static swig wget`

## Usage
- Just run `sudo ./build.sh`.
- Completed builds output to `./output`
- To cleanup and clear all builds, run `sudo ./build.sh clean`

## Flashing
- Take your completed image from `./output` and extract it with gunzip
- Flash directly to an SD card. Example: `dd if=./neo-core2*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`

## To Do
* Bring back kernel overlay support (hoping this gets mainlined for arm64)
* Get bluetooth working on the Plus2 as well as Onboard EMMC boot support

## Notes

- This is only tested on a Debian 9 x86_64 build host. Note your package names may vary per linux distro.
- This code is very dirty, and should only be used as an example. Production use is not advised. Please only proceed if you know what you are doing!
- Public images built from this can be found at [https://images.cblake.io/](https://images.cblake.io/) and are generated monthly as long as things don't break.
