#!/bin/sh

run_and_remove_script() {
	if [ -f ${1} ]; then
		bash ${1}
		mv ${1} "${1}.disabled"
		sync
		sleep 5
		return 0
	fi

	return 1
}

echo "@ beaglebone_boot_staged_setup.sh"

sleep 20

run_and_remove_script "/usr/local/bin/beaglebone_boot_1_grow_partition.sh" && reboot && exit 0
run_and_remove_script "/usr/local/bin/beaglebone_boot_2_fsck_resize.sh" && reboot && exit 0
run_and_remove_script "/usr/local/bin/beaglebone_boot_3_create_swap.sh"

run_and_remove_script "/usr/local/bin/beaglebone_boot_disable_scripts.sh"

exit 0
