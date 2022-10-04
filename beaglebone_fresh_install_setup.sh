#!/bin/bash

# The starting point is the Console image for BeagleBone Black:
# https://beagleboard.org/latest-images
# => https://debian.beagleboard.org/images/bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz

KERNEL_VERSION=4.19.94-ti-r73-hidex.12
KERNEL_IMG_FILENAME="linux-image-hidex-${KERNEL_VERSION}-2_armhf.deb"
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
	echo ""
	echo "********************************************"
	echo "***    disable_mass_storage()            ***"
	echo "********************************************"
	uncomment_line "/etc/default/bb-boot" "USB_IMAGE_FILE_DISABLED=yes"
}

disable_audio_video_overlays() {
	echo ""
	echo "********************************************"
	echo "***    disable_audio_video_overlays()    ***"
	echo "********************************************"
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_audio=1"
	uncomment_line "/boot/uEnv.txt" "disable_uboot_overlay_video=1"
}

enable_rtc_overlay() {
	echo ""
	echo "********************************************"
	echo "***    enable_rtc_overlay()              ***"
	echo "********************************************"
	uncomment_line "/boot/uEnv.txt" "uboot_overlay_addr4=/lib/firmware/BB-I2C2-RTC-DS1307.dtbo"
}

enable_pru_overlay() {
	echo ""
	echo "********************************************"
	echo "***    enable_pru_overlay()              ***"
	echo "********************************************"
	comment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC-4-19-TI-00A0.dtbo"
	uncomment_line "/boot/uEnv.txt" "uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO-00A0.dtbo"
}

disable_dnsmasq_logging() {
	echo ""
	echo "********************************************"
	echo "***    disable_dnsmasq_logging()         ***"
	echo "********************************************"
	grep -qE "^log-facility=/dev/null" /etc/dnsmasq.conf || echo "log-facility=/dev/null" >> /etc/dnsmasq.conf
}

disable_login_msgs() {
	echo ""
	echo "********************************************"
	echo "***    disable_login_msgs()              ***"
	echo "********************************************"

	# Disable the unnecessary login infos and MOTDs
	comment_line "/etc/ssh/sshd_config" "Banner /etc/issue.net"

	if [ ! -f /etc/motd.orig ]; then
		mv /etc/motd /etc/motd.orig && touch /etc/motd
	fi
}

download_and_install_hidex_kernel() {
	echo ""
	echo "********************************************"
	echo "*** download_and_install_hidex_kernel()  ***"
	echo "********************************************"

	cd /home/debian
	mkdir -p hidex_packages
	cd hidex_packages

	# test -f "${LIBC_NAME}" || wget https://github.com/hidex-oy/linux/releases/download/2/${LIBC_NAME}
	test -f "${LIBC_NAME}" && dpkg -i ./${LIBC_NAME}

	test -f "${KERNEL_IMG_FILENAME}" || wget https://github.com/hidex-oy/linux/releases/download/${KERNEL_VERSION}/${KERNEL_IMG_FILENAME}
	dpkg -i ./${KERNEL_IMG_FILENAME}

	cd /home/debian

	# Update the boot loader file to point to the new kernel.
	# The kernel package for 4.19.94-ti-r73-hidex.12-2 or later should do this automatically.
	#sed -i "\|^uname_r=|s|^uname_r=.*\?$|uname_r=${KERNEL_VERSION}+|" /boot/uEnv.txt

	apt-get remove -y linux-image-4.19.94-ti-r42
}

install_required_packages() {
	echo ""
	echo "********************************************"
	echo "***     install_required_packages()      ***"
	echo "********************************************"

	cd /home/debian/hidex_packages

	dpkg -i ./hidex-beaglebone-configs-1.0.0_armhf.deb

	locale-gen
	update-locale

	dpkg -i ./hidex-beaglebone-scripts-1.0.0_armhf.deb
	dpkg -i ./hidex-beaglebone-cape-eeprom-1.0.0-beta.1_armhf.deb
	dpkg -i ./hidex-beaglebone-dtbo-1.0.0-beta.1_armhf.deb

	apt-get install -y locales i2c-tools socat unzip zip libicu63 libusb-1.0-0 libhidapi-libusb0 libhidapi-hidraw0 libhidapi-dev
	#apt-get install -y python3 python3-pip

	#apt-get install -y libusb-1.0-0

	# LibUsbDotNet 2.x is searching for libusb-1.0.so instead of libusb-1.0.so.0
	# libusb-dev would create the /lib/arm-linux-gnueabihf/libusb-1.0.so symlink (that points to libusb-1.0.so.0.1.0)
	# But libusb-dev would pull a few extra packages as dependencies, so let's instead just create the symlink manually
	# in the setup_configs() method.
	#apt-get install -y libusb-dev

	#apt-get install -y i2c-tools
	#apt-get install -y locales
	#apt-get install -y net-tools	# the base installation already has net-tools
	#apt-get install -y unzip
	#apt-get install -y zip

	# socat is a dependency of hidex-detector-forwarding
	#apt-get install -y socat

	# Required for Hidex Control Platform:

	# Note: The version may need to change at some point... and there is no meta package, wtf >_>
	#apt-get install -y libicu63

	#apt-get install -y libhidapi-hidraw0
	#apt-get install -y libhidapi-libusb0

	# Is this needed?
	#apt-get install -y libhidapi-dev
}

disable_useless_services() {
	echo ""
	echo "********************************************"
	echo "***    disable_useless_services()        ***"
	echo "********************************************"

	systemctl disable bluetooth.service
	systemctl disable cron.service
	systemctl disable rsync.service
	systemctl disable wpa_supplicant.service
}

update_package_repo() {
	echo ""
	echo "********************************************"
	echo "***    update_package_repo()             ***"
	echo "********************************************"

	apt-get update
}

update_all_packages() {
	echo ""
	echo "********************************************"
	echo "***    update_all_packages()             ***"
	echo "********************************************"

	apt-get upgrade -y
}

download_files() {
	echo ""
	echo "********************************************"
	echo "***    download_files()                  ***"
	echo "********************************************"

	# Configs
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/dot_bashrc -O /home/debian/.bashrc.new

	mkdir -p /home/debian/hidex_packages/
	cd /home/debian/hidex_packages/

	#wget https://github.com/hidex-oy/beaglebone_configs/releases/download/v1.0.0/hidex-beaglebone-configs-1.0.0_armhf.deb
	#wget https://github.com/hidex-oy/beaglebone_scripts/releases/download/v1.0.0/hidex-beaglebone-scripts-1.0.0_armhf.deb

	#wget https://github.com/hidex-oy/beaglebone_cape_eeprom/releases/download/v1.0.0-beta.1/hidex-beaglebone-cape-eeprom-1.0.0-beta.1_armhf.deb
	#wget https://github.com/hidex-oy/beaglebone_dtbo/releases/download/v1.0.0-beta.1/hidex-beaglebone-dtbo-1.0.0-beta.1_armhf.deb

	#wget http://192.168.100.55:8080/repository/download/HidexDetectorForwarding_Release/2925:id/hidex-detector-forwarding_1.0.1.deb

	# WLAN USB dongle firmware
	mkdir -p /lib/firmware/mediatek
	cd /lib/firmware/mediatek
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/lib/firmware/mediatek/mt7610u.bin
	# The official repo for some reason gives a 0 byte file when this script is run. But manually fetching it with wget later on works... /shrug
	#wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/mt7610u.bin -O /lib/firmware/mediatek/mt7610u.bin

	cd /home/debian
	wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/wlan_howto.md

	# GPG keys to verify packages to be installed via the install_hidex_pkg.sh script
	wget https://raw.githubusercontent.com/maruohon/identity/master/masa_hidex_pub.asc -O /tmp/masa_hidex_pub.asc
}

setup_configs() {
	echo ""
	echo "********************************************"
	echo "***    setup_configs()                   ***"
	echo "********************************************"

	cd /home/debian

	if [ -f .bashrc.new ]; then
		mv .bashrc .bashrc.orig
		mv .bashrc.new .bashrc
		chown debian:debian .bashrc
		cp .bashrc /root/
	fi

	mkdir -p .ssh
	chmod 700 .ssh

	# Create the symlink so that LibUsbDotNet 2.2.29 finds libusb-1.0
	# This symlink would be created by the libusb-dev package, but it has
	# a bunch of extra dependencies, so no point installing it just for this.
	ln -s libusb-1.0.so.0 /lib/arm-linux-gnueabihf/libusb-1.0.so
	ldconfig # update the cache

	# Import the Hidex employee GPG keys to a separate keyring.
	# These will be used in the install_hidex_pkg.sh script for verifying that only
	# Hidex employee signed packages can be installed via the web interface.
	gpg --keyring hidex-packages --no-default-keyring --import /tmp/masa_hidex_pub.asc

	disable_audio_video_overlays
	disable_mass_storage
	enable_pru_overlay
	enable_rtc_overlay

	disable_dnsmasq_logging
	disable_login_msgs
}

# Note: install_required_packages() needs to happen before setup_configs() to install
# the required scripts and config files in place.

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
