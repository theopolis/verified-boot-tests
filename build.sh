#!/bin/bash

set -e

AMAKE="make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j8"

NORMAL=/opt/spl-automate/u-boot/build-normal
RECOVERY=/opt/spl-automate/u-boot/build-recovery
CERT=/opt/spl-automate/content/cert-store.dtb

# Build U-Boot and SPL using the ROM certificate store.
# We will modify the store included with U-Boot later.
echo "[+] cd u-boot"
cd u-boot
mkdir -p $NORMAL

echo "[+] $AMAKE O=$NORMAL -s fbtp_config"
$AMAKE O=$NORMAL -s fbtp_config
echo ""

echo "[+] $AMAKE O=$NORMAL EXT_DTB=$CERT"
$AMAKE O=$NORMAL EXT_DTB=$CERT
echo ""

mkdir -p $RECOVERY
echo "[+] CONFIG_ASPEED_RECOVERY_BUILD=1 $AMAKE O=$RECOVERY EXT_DTB=$CERT -s fbtp_config"

REC="$(cat $RECOVERY/.config | grep CONFIG_ASPEED_RECOVERY_BUILD=1 || true)"
if [[ "$REC" = "" ]]; then
	$AMAKE O=$RECOVERY EXT_DTB=$CERT -s fbtp_config
	echo "CONFIG_ASPEED_RECOVERY_BUILD=y" >> $RECOVERY/.config
fi
echo ""

echo "[+] CONFIG_ASPEED_RECOVERY_BUILD=1 $AMAKE O=$RECOVERY EXT_DTB=$CERT"
$AMAKE CONFIG_ASPEED_RECOVERY_BUILD=1  O=$RECOVERY EXT_DTB=$CERT
echo ""

# Create a u-boot.img, a FIT containing U-Boot.
# This is provided our subordinate key store and signed appropriately.
echo "[+] $NORMAL/tools/mkimage -f /opt/spl-automate/u-boot-amalgamated.dts -E -k /opt/spl-automate/subordinate -p 0x4000 -r $NORMAL/u-boot.img;"
$NORMAL/tools/mkimage -f /opt/spl-automate/u-boot-amalgamated.dts -E -k /opt/spl-automate/subordinate -p 0x4000 -r $NORMAL/u-boot.img;
echo ""

# Use the actual keys
# echo "[+] $NORMAL/tools/mkimage -f /opt/spl-automate/u-boot-amalgamated.dts -E -k /opt/spl-automate/keys -p 0x4000 -r $NORMAL/u-boot.img;"
# $NORMAL/tools/mkimage -f /opt/spl-automate/u-boot-amalgamated.dts -E -k /opt/spl-automate/keys -p 0x4000 -r $NORMAL/u-boot.img;
# echo ""


# Move the ROM into flash0
echo "[+] dd if=$NORMAL/spl/u-boot-spl.bin of=/opt/spl-automate/content/flash0 conv=notrunc"
dd if=$NORMAL/spl/u-boot-spl.bin of=/opt/spl-automate/content/flash0 conv=notrunc;

# Move the recovery U-Boot into flash0
echo "[+] dd if=$RECOVERY/u-boot.bin of=/opt/spl-automate/content/flash0 bs=1024 skip=64 conv=notrunc"
dd if=$RECOVERY/u-boot.bin of=/opt/spl-automate/content/flash0 bs=1024 seek=64 conv=notrunc

# Move the normal U-Boot into flash0
echo "[+] dd if=$NORMAL/u-boot.img of=/opt/spl-automate/content/flash0 bs=1024 skip=512 conv=notrunc"
dd if=$NORMAL/u-boot.img of=/opt/spl-automate/content/flash0 bs=1024 seek=512 conv=notrunc
echo ""

# Move the same content into flash1
echo "[+] dd if=$NORMAL/spl/u-boot-spl.bin of=/opt/spl-automate/content/flash1 conv=notrunc"
dd if=$NORMAL/spl/u-boot-spl.bin of=/opt/spl-automate/content/flash1 conv=notrunc;

# Move the recovery U-Boot into flash0
echo "[+] dd if=$RECOVERY/u-boot.bin of=/opt/spl-automate/content/flash1 bs=1024 skip=64 conv=notrunc"
dd if=$RECOVERY/u-boot.bin of=/opt/spl-automate/content/flash1 bs=1024 seek=64 conv=notrunc

# Move the normal U-Boot into flash1
echo "[+] dd if=$NORMAL/u-boot.img of=/opt/spl-automate/content/flash1 bs=1024 skip=512 conv=notrunc"
dd if=$NORMAL/u-boot.img of=/opt/spl-automate/content/flash1 bs=1024 seek=512 conv=notrunc

# NOP out second U-Boot (testing)
# dd if=/dev/zero of=/opt/spl-automate/content/flash1 bs=1024 seek=80 count=10240 conv=notrunc
