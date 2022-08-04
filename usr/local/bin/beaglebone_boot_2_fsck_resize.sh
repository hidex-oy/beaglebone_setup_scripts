#!/bin/sh

echo "@ beaglebone_boot_2_fsck_resize.sh"

echo "running fsck /dev/mmcblk0p1"
fsck /dev/mmcblk0p1
sleep 10

echo "running resize2fs /dev/mmcblk0p1"
resize2fs /dev/mmcblk0p1
sleep 10

exit 0
