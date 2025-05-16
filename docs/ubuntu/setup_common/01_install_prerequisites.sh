#!/bin/bash
set -ex

# Don't allow the kernel to be updated
apt-mark hold linux-image-generic linux-headers-generic

# Don't allow the local installed packages to be updated
apt list --installed | grep "\[installed,local\]" | awk -F/ '{print $1}' | xargs apt-mark hold

# Upgrade pre-installed components
apt update
apt upgrade -y