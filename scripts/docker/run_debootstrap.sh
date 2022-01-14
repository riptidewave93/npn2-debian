#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# NOTE THAT THIS IS RUNNING INSIDE AN ARM64 CONTAINER!!! BECAUSE OF THIS, WE GOTTA DO SHIT DIFFERENTLY!

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --foreign --arch=${deb_arch} ${deb_release} ${build_path}/rootfs ${deb_mirror}
chroot ${build_path}/rootfs /usr/bin/qemu-aarch64-static /debootstrap/debootstrap --second-stage