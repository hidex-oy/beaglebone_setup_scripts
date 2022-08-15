#!/bin/sh

echo "@ beaglebone_boot_1_grow_partition.sh"

echo "running /opt/scripts/tools/grow_partition.sh in 10 seconds..."
sleep 10
bash /opt/scripts/tools/grow_partition.sh
sleep 10

exit 0
