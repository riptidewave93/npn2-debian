#!/bin/bash
set -e

GENIMAGE_ROOT=$(mktemp -d)
touch ${GENIMAGE_ROOT}/placeholder

# Generate our boot and rootfs disk images
genimage                         \
	--rootpath "${GENIMAGE_ROOT}"     \
	--tmppath "/tmp/genimage-initial-tmppath"    \
	--inputpath "/repo/BuildEnv"  \
	--outputpath "/repo/BuildEnv" \
	--config "/repo/genimage_initial.cfg"
