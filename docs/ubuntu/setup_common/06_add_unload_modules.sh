#!/bin/bash
set -ex

# Unload Kernel driver i2c-piix4, it is an Intel chip for a PIIX4 SMBus controller, not using on the virtual environment.
echo "blacklist i2c_piix4" | tee -a /etc/modprobe.d/blacklist-mdx-ubuntu.conf

# Update initramfs.
sudo update-initramfs -u -k all