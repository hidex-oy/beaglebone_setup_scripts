#!/bin/sh

# Turn off the VLDO2 line entirely.
# More recent BeagleBone Black board versions allow doing this.
# Early board versions (before A6) do not allow this without
# turning off the entire 3V3B rail and thus messing up everything/rebooting the system.
i2cset -f -y 0 0x24 0x0B 0x6B
i2cset -f -y 0 0x24 0x16 0x7E

# Alternative approach:
# Write a lower voltage level to turn off the power LED.
# The register is Level2 protected, so it needs to be unlocked and written twice
# i2cset -f -y 0 0x24 0x0B 0x6e
# i2cset -f -y 0 0x24 0x13 0x23
# i2cset -f -y 0 0x24 0x0B 0x6e
# i2cset -f -y 0 0x24 0x13 0x23
