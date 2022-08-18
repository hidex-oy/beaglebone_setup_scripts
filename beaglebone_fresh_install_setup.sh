#!/bin/sh

# The starting point is the Console image for BeagleBone Black:
# https://beagleboard.org/latest-images
# => https://debian.beagleboard.org/images/bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz

KERNEL_VERSION=4.19.94-ti-r73-hidex.10
KERNEL_IMG_FILENAME="linux-image-hidex-${KERNEL_VERSION}_armhf.deb"
LIBC_NAME="linux-libc-dev_4.19.94hidex2+-19_armhf.deb"

uncomment_line() {
	FILENAME=$1
	LINE=$2

	# If the line already exists, then uncomment it, if necessary
	if grep -qF "${LINE}" ${FILENAME} ; then
		echo "uncomment_line(): Uncommenting line ${LINE} in ${FILENAME}"
		sed -i "\|^#\+\\s*${LINE}$|s|^#\+\\s*||" ${FILENAME}
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

disable_dnsmasq_logging() {
	grep -qE "^log-facility=/dev/null" /etc/dnsmasq.conf || echo "log-facility=/dev/null" >> /etc/dnsmasq.conf
}

disable_login_msgs() {
	echo "*** Disable login messages"

	# Disable the unnecessary login infos and MOTDs
	comment_line "/etc/ssh/sshd_config" "Banner /etc/issue.net"

	if [ ! -f /etc/motd.orig ]; then
		mv /etc/motd /etc/motd.orig && touch /etc/motd
	fi
}

download_and_install_hidex_kernel() {
	echo "*** Download and install Hidex kernel"

	cd /home/debian
	mkdir -p hidex_packages
	cd hidex_packages

	# test -f "${LIBC_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${LIBC_NAME}
	test -f "${LIBC_NAME}" && dpkg -i ./${LIBC_NAME}

	test -f "${KERNEL_IMG_FILENAME}" || wget https://github.com/hidex-oy/linux/releases/download/${KERNEL_VERSION}/${KERNEL_IMG_FILENAME}
	dpkg -i ./${KERNEL_IMG_FILENAME}

	cd /home/debian

	# Update the boot loader file to point to the new kernel
	sed -i "\|^uname_r=|s|^uname_r=.*\?$|uname_r=${KERNEL_VERSION}+|" /boot/uEnv.txt

	apt-get remove -y linux-image-4.19.94-ti-r42
}

install_required_packages() {
	echo "*** Install required packages"

	apt-get install -y locales i2c-tools unzip zip libicu63 libhidapi-libusb0 libhidapi-dev

	#apt-get install -y locales
	#apt-get install -y i2c-tools
	#apt-get install -y unzip
	#apt-get install -y zip

	# Required for Hidex Control Platform:

	# Note: The version may need to change at some point... and there is no meta package, wtf >_>
	#apt-get install -y libicu63

	#apt-get install -y libhidapi-libusb0

	# Is this needed?
	# apt-get install -y libhidapi-dev
}

disable_useless_services() {
	echo "*** Disable useless services"

	systemctl disable bluetooth.service
	systemctl disable cron.service
	systemctl disable rsync.service
	systemctl disable wpa_supplicant.service
}

update_package_repo() {
	echo "*** Update package repo"

	apt-get update
}

update_all_packages() {
	echo "*** Update all packages"

	apt-get upgrade -y
}

download_files() {
	echo "*** Download files"

	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/home/debian/.bashrc -O /home/debian/.bashrc.new
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/etc/rc.local -O /etc/rc.local
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/etc/locale.gen -O /etc/locale.gen

	cd /usr/local/bin
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_enable_staged_boot_scripts.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_staged_setup.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_1_grow_partition.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_2_fsck_resize.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_3_create_swap.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_boot_disable_scripts.sh

	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_black_user_leds_off.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_black_user_leds_on.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_black_power_led_off.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/beaglebone_black_power_led_on.sh
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/usr/local/bin/eeprom_write.sh

	# cd /home/debian/hidex-packages
	# wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/deb/linux-firmware-hidex-beaglebone-1.0.0.deb

	mkdir -p /lib/firmware/mediatek
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/lib/firmware/mediatek/mt7610u.bin -O /lib/firmware/mediatek/mt7610u.bin
	# The official repo for some reason gives a 0 byte file when this script is run. But manually fetching it with wget later on works... /shrug
	#wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/mt7610u.bin -O /lib/firmware/mediatek/mt7610u.bin

	cd /lib/firmware
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/dtbo/HIDEX-LEDCAPE-C2-00C2.dtbo

	cd /home/debian
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/wlan_howto.md

	mkdir -p eeprom
	cd eeprom
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/eeprom/eeprom_hidex_ledcape_c2_4.bin

	cd /home/debian
}

setup_configs() {
	echo "*** Setup configs"

	chmod 755 /etc/rc.local
	chmod +x /usr/local/bin/*

	cd /home/debian

	if [ -f .bashrc.new ]; then
		mv .bashrc .bashrc.orig
		mv .bashrc.new .bashrc
		chown debian:debian .bashrc
	fi

	mkdir -p .ssh
	chmod 700 .ssh

	disable_audio_video_overlays
	disable_mass_storage
	enable_pru_overlay
	enable_rtc_overlay

	disable_dnsmasq_logging
	disable_login_msgs
}

download_files
update_package_repo
install_required_packages
setup_configs
update_all_packages
download_and_install_hidex_kernel
disable_useless_services

chown -R debian:debian /home/debian
apt-get clean

echo ""
echo "**************************"
echo "******* Setup DONE *******"
echo "**************************"
echo ""
echo "Please reboot now!"
echo ""
echo "After that, the installation and update of the base system is be done."
echo ""
echo "Next you should install all the necessary packages (Hidex Control Platform etc.)"
echo "that you want in the final image, and once those are all installed,"
echo "then run the script /usr/local/bin/beaglebone_enable_staged_boot_scripts.sh"
echo ""
echo "Then shutdown the BeagleBone (without rebooting!) and take a disk image."
echo ""
echo "That image will then have the scripts enabled for expanding the partition"
echo "and setting up and enabling swap space etc. during the first few boots."
