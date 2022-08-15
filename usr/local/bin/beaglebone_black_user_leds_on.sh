#!/bin/sh

# Disable the heartbeat LED
echo none > /sys/class/leds/beaglebone\:green\:usr0/trigger

# Enable the mmc0 LED
echo mmc0 > /sys/class/leds/beaglebone\:green\:usr1/trigger

# Enable the cpu0 LED
echo cpu0 > /sys/class/leds/beaglebone\:green\:usr2/trigger

# Enable the mmc1 LED
echo mmc1 > /sys/class/leds/beaglebone\:green\:usr3/trigger
