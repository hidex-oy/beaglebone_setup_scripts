#!/bin/sh

# Disable the heartbeat LED
echo none > /sys/class/leds/beaglebone\:green\:usr0/trigger

# Disable the mmc0 LED
echo none > /sys/class/leds/beaglebone\:green\:usr1/trigger

# Disable the cpu0 LED
echo none > /sys/class/leds/beaglebone\:green\:usr2/trigger

# Disable the mmc1 LED
echo none > /sys/class/leds/beaglebone\:green\:usr3/trigger
