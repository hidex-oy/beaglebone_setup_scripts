#!/bin/sh

WORK_DIR=/tmp/pkgupg
# The packages (if verified) are left in this directory, if KEEP_PACKAGES is "true"
PACKAGE_ARCHIVE_DIR=/home/debian/packages
INSTALL_ARCHIVE_FILE=/home/debian/dropinstall.tar.gz
KEEP_PACKAGES=false

if [ $# = 1 ]; then
	INSTALL_ARCHIVE_FILE=`realpath $1`
fi

if [ ! -f ${INSTALL_ARCHIVE_FILE} ]; then
	echo "No installation package file at ${INSTALL_ARCHIVE_FILE} !"
	exit 1
fi

PWD=`pwd`
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

echo "Extracting archive ${INSTALL_ARCHIVE_FILE}..."
tar xvf ${INSTALL_ARCHIVE_FILE}

if [ $? != 0 ] || [ ! -f hash.txt ] || [ ! -f hash.txt.sig ]; then
	echo "Not a valid update archive!"
	exit 1
fi

echo "Verifying the hash file integrity..."

# Use a separate keyring for these packages, so that no other existing keys would match.
# Not that it would happen anyway, as there are no other keys by default...
# This keyring should have the necessary/allowed keys imported during the BeagleBone
# SD card basic image installation (done in the beaglebone_fresh_install_setup.sh script).
gpg --keyring hidex-packages --no-default-keyring --verify hash.txt.sig

if [ $? != 0 ]; then
	echo "Failed to verify the package integrity!"
	exit 1
fi

echo "Checking package file hashes..."
sha1sum -c hash.txt

if [ $? != 0 ]; then
	echo "Package checksum(s) failed!"
	exit 1
fi

if [ "x${KEEP_PACKAGES}" = "xtrue" ]; then
	echo "Copying the packages to ${PACKAGE_ARCHIVE_DIR}"
	mkdir -p ${PACKAGE_ARCHIVE_DIR}
	cp -p *.deb ${PACKAGE_ARCHIVE_DIR}
fi

echo "Installing the packages..."

while read sha1 name; do
	echo "dpkg -i ./${name}"
	dpkg -i ./${name}
done < "hash.txt"

cd ${PWD}
rm -r ${WORK_DIR}
