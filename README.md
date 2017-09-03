# npn2-debian

Build script to build a Debian 9 image for the NanoPi Neo2, as well as all dependencies. This includes the following:

- Mainline Linux Kernel - Set to 4.13-rc7
- Arm Trusted Firmware - [allwinner/sunxi branch](https://github.com/apritzel/arm-trusted-firmware/tree/allwinner)
- Mainline U-Boot - Set to v2017.09-rc3

## Requirements

- The following packages on your build host: `bc binfmt-support build-essential debootstrap device-tree-compiler dosfstools fakeroot git kpartx lvm2 parted qemu qemu-user-static wget`

## Usage
- Just run `./build.sh` as root.
- Completed builds output to `./output/headless_debian_stretch_arm64_*.img.gz`

## Notes

- This is only tested on a Debian 9 x86_64 build host. Note your package names may vary per linux distro.
- This code is very dirty, and should only be used as an example. Production use is not advised. Please only proceed if you know what you are doing!
- Public images built from this can be found at [https://images.chrisrblake.com/](https://images.chrisrblake.com/) and are updated monthly.

## ToDo
* Backport thermal driver (or wait for 4.14?)
* Verify all USB interfaces are enabled
