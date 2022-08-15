#!/bin/sh

echo "@ beaglebone_boot_2_fsck_resize.sh"

echo "running fsck /dev/mmcblk0p1 in 10 seconds..."
sleep 10
fsck /dev/mmcblk0p1

echo "running resize2fs /dev/mmcblk0p1 in 10 seconds..."
sleep 10
resize2fs /dev/mmcblk0p1

sleep 10

exit 0
