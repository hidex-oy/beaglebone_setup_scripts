#!/bin/sh

echo "@ beaglebone_boot_1_grow_partition.sh"

sleep 60
echo "running /opt/scripts/tools/grow_partition.sh"
bash /opt/scripts/tools/grow_partition.sh
sleep 10

exit 0
