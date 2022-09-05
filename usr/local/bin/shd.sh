#!/bin/sh

/usr/local/bin/beaglebone_black_power_led_on.sh
/usr/local/bin/beaglebone_black_user_leds_on.sh

sleep 1

shutdown -h now
