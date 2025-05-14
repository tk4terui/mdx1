#!/bin/bash
set -ex

# Kernel Parameter to disable predictive network interface naming
KERNEL_PARAMETER="net.ifnames=0"

# Change grub parameters
sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=8/' /etc/default/grub
sed -i "s/GRUB_CMDLINE_LINUX=\".*/GRUB_CMDLINE_LINUX=\"${KERNEL_PARAMETER}\"/" /etc/default/grub

# Generate grub file with updated parameters 
update-grub