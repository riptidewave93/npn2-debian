# Our AIO builder docker file
FROM debian:11

RUN mkdir /repo
COPY ./scripts/docker/setup_mkimage.sh /setup_mkimage.sh

RUN apt-get update && apt-get install -yq \
    autoconf \
    bc \
    binfmt-support \
    bison \
    bsdextrautils \
    build-essential \
    cpio \
    debootstrap \
    device-tree-compiler \
    dosfstools \
    fakeroot \
    flex \
    genext2fs \
    git \
    kmod \
    kpartx \
    libconfuse-common \
    libconfuse-dev \
    libssl-dev \
    lvm2 \
    mtools \
    parted \
    pkg-config \
    python-dev \
    python-setuptools \
    python3-dev \
    python3-setuptools \
    qemu \
    qemu-user-static \
    rsync \
    swig \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && /setup_mkimage.sh \
    && rm /setup_mkimage.sh