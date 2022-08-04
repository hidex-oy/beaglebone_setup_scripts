#!/bin/sh

uncomment_line() {
	FILENAME=$1
	LINE=$2

	# If the line already exists, then uncomment it, if necessary
	if grep -qF "${LINE}" ${FILENAME} ; then
		echo "uncomment_line(): Uncommenting line ${LINE} in ${FILENAME}"
		sed -i "\|^#\+\\s*${LINE}|s|^#\+\\s*||" ${FILENAME}
	else
		# Add the line if it doesn't exist at all
		echo "uncomment_line(): Adding line ${LINE} to ${FILENAME}"
		echo "${LINE}" >> ${FILENAME}
	fi
}

echo "@ beaglebone_enable_staged_boot_scripts.sh"

uncomment_line "/etc/rc.local" "/usr/local/bin/beaglebone_boot_staged_setup.sh"

exit 0
