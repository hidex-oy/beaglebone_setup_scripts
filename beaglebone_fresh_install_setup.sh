#!/bin/sh

# The starting point is the Console image for BeagleBone Black:
# https://beagleboard.org/latest-images
# => https://debian.beagleboard.org/images/bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz

IMG_NAME="linux-image-4.19.94hidex2+_4.19.94hidex2+-19_armhf.deb"
LIBC_NAME="linux-libc-dev_4.19.94hidex2+-19_armhf.deb"

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

comment_line() {
	FILENAME=$1
	LINE=$2

	# If the line already exists, then comment it, if necessary
	if grep -qF "${LINE}" ${FILENAME} ; then
		echo "comment_line(): Commenting out line ${LINE} in ${FILENAME}"
		sed -i "\|^${LINE}|s|^|#|" ${FILENAME}
	fi
}

disable_mass_storage() {
	uncomment_line "/etc/default/bb-boot" "USB_IMAGE_FILE_DISABLED=yes"
}

disable_audio_video_overlays() {
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_audio=1"
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_video=1"
}

enable_rtc_overlay() {
	uncomment_line "/boot/uEnv.txt" "uboot_overlay_addr4=/lib/firmware/BB-I2C2-RTC-DS1307.dtbo"
}

enable_pru_overlay() {
	comment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC-4-19-TI-00A0.dtbo"
	uncomment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO-00A0.dtbo"
}

download_and_install_hidex_kernel() {
	cd /home/debian
	mkdir -p hidex_packages
	cd hidex_packages

	test -f "${IMG_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${IMG_NAME}
	test -f "${LIBC_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${LIBC_NAME}

	apt-get install ./${IMG_NAME} ./${LIBC_NAME}

	cd /home/debian
}

disable_useless_services() {
	systemctl disable bluetooth.service
	systemctl disable cron.service
	systemctl disable rsync.service
	systemctl disable wpa_supplicant.service
}

update_all_packages() {
	apt-get update
	apt-get upgrade -y
	apt-get clean
}

setup_configs() {
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/home/debian/.bashrc -O /home/debian/.bashrc.new
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/etc/rc.local -O /etc/rc.local

	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_enable_staged_boot_scripts.sh -O /usr/local/bin/beaglebone_enable_staged_boot_scripts.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_staged_setup.sh -O /usr/local/bin/beaglebone_boot_staged_setup.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_1_grow_partition.sh -O /usr/local/bin/beaglebone_boot_1_grow_partition.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_2_fsck_resize.sh -O /usr/local/bin/beaglebone_boot_2_fsck_resize.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_3_create_swap.sh -O /usr/local/bin/beaglebone_boot_3_create_swap.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_disable_scripts.sh -O /usr/local/bin/beaglebone_boot_disable_scripts.sh

	chmod 755 /etc/rc.local

	cd /home/debian

	if [ -f .bashrc.new ]; then
		mv .bashrc .bashrc.orig
		mv .bashrc.new .bashrc
		chown debian:debian .bashrc
	fi

	mkdir -p .ssh
	chmod 700 .ssh

	grep -qE "^log-facility=/dev/null" /etc/dnsmasq.conf || echo "log-facility=/dev/null" >> /etc/dnsmasq.conf

	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_audio=1"
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_video=1"

	uncomment_line "/boot/uEnv.txt" "uboot_overlay_addr4=/lib/firmware/BB-I2C2-RTC-DS1307.dtbo"

	comment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC-4-19-TI-00A0.dtbo"
	uncomment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO-00A0.dtbo"

	uncomment_line "/etc/default/bb-boot" "USB_IMAGE_FILE_DISABLED=yes"

	# Disable the unnecessary login infos and MOTDs
	comment_line "/etc/ssh/sshd_config" "Banner /etc/issue.net"
	mv /etc/motd /etc/motd.orig
	touch /etc/motd
}

setup_configs
update_all_packages
download_and_install_hidex_kernel
disable_useless_services

#disable_mass_storage
#disable_audio_video_overlays
#enable_pru_overlay
#enable_rtc_overlay

# Remove the original kernel's modules
rm -fr /lib/modules/4.*-ti-*

echo ""
echo "**************************"
echo "******* Setup DONE *******"
echo "**************************"
echo ""
echo "Please unplug the network cable and then reboot!"
echo ""
echo "After that, the base installation should be done."
echo ""
echo "Then you should install all the necessary packages (Hidex Control Platform etc.)"
echo "that you want in the final image, and once those are all installed,"
echo "then run the script /usr/local/bin/beaglebone_enable_staged_boot_scripts.sh"
echo ""
echo "Then shutdown the BeagleBone (without rebooting!) and take a disk image."
echo ""
echo "That image will then have the scripts enabled for expanding the partition"
echo "and setting up and enabling swap space etc. during the first few boots."
