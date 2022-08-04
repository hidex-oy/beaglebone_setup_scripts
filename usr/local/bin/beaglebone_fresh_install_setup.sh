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
		echo "uncomment_line(): Uncommenting line"
		sed -i "\|^#\+\\s*${LINE}|s|^#\+\\s*||" ${FILENAME}
	else
		# Add the line if it doesn't exist at all
		echo "uncomment_line(): Adding line"
		echo "${LINE}" >> ${FILENAME}
	fi
}

comment_line() {
	FILENAME=$1
	LINE=$2

	# If the line already exists, then comment it, if necessary
	if grep -qF "${LINE}" ${FILENAME} ; then
		echo "comment_line(): Commenting out line"
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
	mkdir -p hidex_packages
	cd hidex_packages
	test -f "${IMG_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${IMG_NAME}
	test -f "${LIBC_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${LIBC_NAME}
	cd ..

	apt-get install ./hidex_packages/${IMG_NAME} ./hidex_packages/${LIBC_NAME}
}

disable_useless_services() {
	systemctl disable bluetooth.service
	systemctl disable cron.service
	systemctl disable rsync.service
	systemctl disable wpa_supplicant.service
}

setup_configs() {
	# wget https://raw.githubusercontent.com/hidex-oy/beaglebone_configs/master/.bashrc -O .bashrc.new
	wget https://pastebin.com/raw/DudbPWHH -O .bashrc.new

	if [ -f .bashrc.new ]; then
		mv .bashrc .bashrc.orig
		mv .bashrc.new .bashrc
	fi

	mkdir -p .ssh
	chmod 600 .ssh

	grep -qE "^log-facility=/dev/null" /etc/dnsmasq.conf || echo "log-facility=/dev/null" >> /etc/dnsmasq.conf

	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_audio=1"
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_video=1"

	uncomment_line "/boot/uEnv.txt" "uboot_overlay_addr4=/lib/firmware/BB-I2C2-RTC-DS1307.dtbo"

	uncomment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO-00A0.dtbo"
	comment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC-4-19-TI-00A0.dtbo"

	uncomment_line "/etc/default/bb-boot" "USB_IMAGE_FILE_DISABLED=yes"
}

update_all_packages() {
	apt-get update
	apt-get upgrade -y
}

cd /home/debian

setup_configs
disable_useless_services
update_all_packages
download_and_install_hidex_kernel

#disable_mass_storage
#disable_audio_video_overlays
#enable_pru_overlay
#enable_rtc_overlay

# Remove the original kernel's modules
rm -fr /lib/modules/4.19.*-ti-*

echo "please unplug the network cable and reboot now!"
