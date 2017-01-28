FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
    git \
    wget \
    ruby \
    ruby-dev \
    python \
    python-dev \
    build-essential \
    curl

RUN mkdir /opt/spl-automate
RUN mkdir /opt/spl-automate/content

RUN git clone -b ast2500-edk-mods https://github.com/theopolis/qemu /opt/spl-automate/qemu
RUN git clone -b openbmc/helium/v2016.07 https://github.com/theopolis/u-boot /opt/spl-automate/u-boot

RUN apt-get install -y pkg-config zlib1g-dev libglib2.0-dev libfdt-dev autoconf libtool

RUN (cd /opt/spl-automate/qemu; git submodule update --init pixman)
RUN (cd /opt/spl-automate/qemu; ARCH=arm CROSS_COMPILE=arm-none-eabi- ./configure --target-list=arm-softmmu)

RUN dd if=/dev/zero of=/opt/spl-automate/content/flash0 bs=1k count=32768
RUN dd if=/dev/zero of=/opt/spl-automate/content/flash1 bs=1k count=32768

COPY . /opt/spl-automate

RUN apt-get install -y gcc-arm-none-eabi libssl-dev device-tree-compiler bc
RUN (cd /opt/spl-automate/; /opt/spl-automate/build.sh)
