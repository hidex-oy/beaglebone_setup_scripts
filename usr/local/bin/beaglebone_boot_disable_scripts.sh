#!/bin/sh

comment_line() {
	FILENAME=$1
	LINE=$2

	# If the line already exists, then comment it, if necessary
	if grep -qF "${LINE}" ${FILENAME} ; then
		echo "comment_line(): Commenting out line ${LINE} in ${FILENAME}"
		sed -i "\|^${LINE}|s|^|#|" ${FILENAME}
	fi
}

echo "@ beaglebone_boot_4_disable_boot_setup_scripts.sh"

comment_line "/etc/rc.local" "/usr/local/bin/beaglebone_boot_staged_setup.sh"

exit 0
