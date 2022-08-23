#!/bin/sh

if [ $# -lt 2 ] || [ ! -d $1 ]; then
	echo "Usage: $0 <dir> <output file> [GPG key ID]"
	echo "  - <dir> is the directory containing the *.deb packages"
	echo "    to create the install package from"
	echo "  - <output file> is the output install archive file to create"
	echo "  - [GPG key ID] is optional, it's the GPG key ID to use for signing,"
	echo "    if the default key ID should not be used."
	exit 1
fi

DIR=$1
OUTPUT_FILE=`realpath $2`

echo "out: ${OUTPUT_FILE}"

if [ -f ${OUTPUT_FILE} ]; then
	echo "Error: The output file ${OUTPUT_FILE} already exists, aborting!"
	exit 1
fi

if [ $# = 3 ]; then
	GPG_USER="--local-user $3"
fi

cd ${DIR}

if [ -f hash.txt ] || [ -f hash.txt.sig ]; then
	echo "Error: The file hash.txt or hash.txt.sig already exists in ${DIR}, aborting!"
	exit 1
fi

sha1sum *.deb > hash.txt
gpg ${GPG_USER} --detach-sign hash.txt

if [ $? != 0 ]; then
	echo "Failed to sign the hash file"
	exit 1
fi

tar czf ${OUTPUT_FILE} *.deb hash.txt hash.txt.sig
rm hash.txt
rm hash.txt.sig
