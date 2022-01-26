#!/bin/bash
set -e

GENIMAGE_SRC="https://github.com/pengutronix/genimage/releases/download/v15/genimage-15.tar.xz"
GENIMAGE_FILENAME="$(basename $GENIMAGE_SRC)"
GENIMAGE_REPOPATH="${GENIMAGE_FILENAME%.tar.xz}"

cd /usr/src
echo "Downloading genimage..."
wget ${GENIMAGE_SRC} -O /usr/src/${GENIMAGE_FILENAME}

echo "Extracting genimage..."
tar -xJf /usr/src/${GENIMAGE_FILENAME}

echo "Building genimage..."
cd ./${GENIMAGE_REPOPATH}
./configure
make

echo "Installing genimage..."
make install

echo "Cleaning up..."
rm -rf /usr/src/${GENIMAGE_REPOPATH}*

exit 0