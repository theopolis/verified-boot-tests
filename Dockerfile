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

RUN apt-get install -y gcc-arm-none-eabi libssl-dev device-tree-compiler bc

ENV NORMAL=/opt/spl-automate/u-boot/build-normal
RUN mkdir -p $NORMAL

ENV RECOVERY=/opt/spl-automate/u-boot/build-recovery
RUN mkdir -p $RECOVERY

RUN apt-get install -y python-pip
RUN echo hii
RUN git clone https://github.com/theopolis/fit-certificate-store /opt/spl-automate/fit-certificate-store
RUN pip install jinja2 pycrypto

COPY . /opt/spl-automate

# We will need a KEK public key for the normal build, which produces a ROM.
# This is copying a pre-generated key.
#  mkdir -p kek
#  openssl genrsa -F4 -out kek/kek.key 4096
#  openssl rsa -in kek/kek.key -pubout > kek/kek.pub

ENV ROM_STORE=/opt/spl-automate/content/rom-store.dtb
RUN /opt/spl-automate/fit-certificate-store/fit-cs.py \
  --template /opt/spl-automate/fit-certificate-store/store.dts.in \
  --required-node image /opt/spl-automate/kek $ROM_STORE

# Enable features for FBTP to build (1) in QEMU and (2) an SPL ROM.
RUN (cd /opt/spl-automate/u-boot; git apply ../qemu-rom.patch)

# This will build "normal" U-Boot
ENV AMAKE="make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j4"
ENV CONFIG=fbtp_config

RUN (cd /opt/spl-automate/u-boot; $AMAKE O=$NORMAL -s $CONFIG)
RUN (cd /opt/spl-automate/u-boot; $AMAKE O=$NORMAL EXT_DTB=$ROM_STORE)

# Now build the recovery U-Boot
RUN (cd /opt/spl-automate/u-boot; $AMAKE O=$RECOVERY -s $CONFIG)
RUN echo "CONFIG_ASPEED_RECOVERY_BUILD=y" >> $RECOVERY/.config
RUN (cd /opt/spl-automate/u-boot; $AMAKE O=$RECOVERY EXT_DTB=$ROM_STORE)
