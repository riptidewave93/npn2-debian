# npn2-debian

Build script to build a Debian 9 image for NanoPi H5 based boards, as well as all dependencies. This includes the following:

- Mainline Linux Kernel - [4.15-rc6](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v4.15-rc6)
- Arm Trusted Firmware - [allwinner/sunxi branch](https://github.com/apritzel/arm-trusted-firmware/tree/allwinner)
- Mainline U-Boot [v2017.11](https://github.com/u-boot/u-boot/tree/v2017.11)

## Supported Boards
Currently images for the following devices are generated:
* FriendlyARM NanoPi Neo2
* FriendlyARM NanoPi Neo Core2 (broken)
* FriendlyARM NanoPi Neo Plus2 (untested)

## Requirements

- The following packages on your build host: `bc binfmt-support build-essential debootstrap device-tree-compiler dosfstools fakeroot git kpartx lvm2 parted qemu qemu-user-static wget`

## Usage
- Just run `sudo ./build.sh`.
- Completed builds output to `./output`
- To cleanup and clear all builds, run `sudo ./build.sh clean`

## To Do
* Fixup Core2 Support
  - Get U-Boot ethernet working
  - Fix kernel panic on boot
* Bring back overlay support

## Notes

- This is only tested on a Debian 9 x86_64 build host. Note your package names may vary per linux distro.
- This code is very dirty, and should only be used as an example. Production use is not advised. Please only proceed if you know what you are doing!
- Public images built from this can be found at [https://images.chrisrblake.com/](https://images.chrisrblake.com/) and are generated monthly.
