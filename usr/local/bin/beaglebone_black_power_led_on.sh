#!/bin/sh

# Turn back on the VLDO2 line.
i2cset -f -y 0 0x24 0x0B 0x6B
i2cset -f -y 0 0x24 0x16 0x7F

# Restore the original voltage level to turn on the power LED.
# The register is Level2 protected, so it needs to be unlocked and written twice
# i2cset -f -y 0 0x24 0x0B 0x6e
# i2cset -f -y 0 0x24 0x13 0x38
# i2cset -f -y 0 0x24 0x0B 0x6e
# i2cset -f -y 0 0x24 0x13 0x38
