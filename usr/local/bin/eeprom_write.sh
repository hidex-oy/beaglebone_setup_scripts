#!/bin/sh

EEPROM_ADDR="57"
I2C_BUS_ADDR="2-00${EEPROM_ADDR}"

if [ $# -ne 1 ]; then
	echo "Usage: $0 <eeprom_data_file>"
	exit 1
fi

FILE=$1

cat ${FILE} > /sys/bus/i2c/devices/${I2C_BUS_ADDR}/eeprom

sleep 2

cat /sys/bus/i2c/devices/${I2C_BUS_ADDR}/eeprom | hexdump -C
