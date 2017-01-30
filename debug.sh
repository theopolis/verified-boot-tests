#!/usr/bin/env bash

FLASH0=/opt/spl-automate/content/flash0
FLASH1=/opt/spl-automate/content/flash1

dd if=$FLASH1 of=/tmp/uboot.fit bs=1k skip=512 count=50
dtc -I dtb -O dts /tmp/uboot.fit

dd if=$FLASH1 of=/tmp/uboot.content bs=1k skip=528 count=1
hexdump -C /tmp/uboot.content
