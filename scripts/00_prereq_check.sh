#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 00_prereq_check.sh"

# Do we have what we need locally?

# losetup
if ! which losetup > /dev/null; then
    error_msg "losetup is missing! Exiting..."
    exit 1
fi

# Make sure loop module is loaded
if [ ! -d /sys/module/loop ]; then
    error_msg "Loop module isn't loaded into the kernel! This is REQUIRED! Exiting..."
    exit 1
fi

# docker
if ! which docker > /dev/null; then
    error_msg "docker is missing! Exiting..."
    exit 1
fi

# wget
if ! which docker > /dev/null; then
    error_msg "wget is missing! Exiting..."
    exit 1
fi

# sudo
if ! which sudo > /dev/null; then
    error_msg "sudo is missing! Exiting..."
    exit 1
fi

debug_msg "Finished 00_prereq_check.sh"
