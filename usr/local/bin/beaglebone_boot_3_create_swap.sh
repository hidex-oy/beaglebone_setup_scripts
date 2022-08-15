#!/bin/sh

SWAP_FILE="/swapfile"
SWAP_SIZE=2048 # the size of the swap file, in megabytes

create_swap_file() {
	if [ -f "${SWAP_FILE}" ]; then
		# rm "${SWAP_FILE}"
		exit 1
	fi

	echo "Creating the swap file"
	dd if=/dev/zero of=${SWAP_FILE} bs=1M count=${SWAP_SIZE}
	chmod 600 ${SWAP_FILE}
	mkswap -f ${SWAP_FILE}
}

enable_swap_file() {
	echo "Adding the swap file to /etc/fstab"

	# If the exact line already exists, then do nothing
	grep -qE "^${SWAP_FILE}\s+swap\s+swap\s+defaults\s+0\s+0" /etc/fstab && return 0

	# Comment out any old swap lines
	sed -i '\|^\\s*[^#]\+\\s\+swap\\s\+|s|^|#|' /etc/fstab

	# Add the new swap line
	echo "${SWAP_FILE}	swap	swap	defaults	0	0" >> /etc/fstab

	swapon ${SWAP_FILE}
}

echo "@ beaglebone_boot_3_create_swap.sh"

create_swap_file
enable_swap_file

exit 0
