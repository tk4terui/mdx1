#!/bin/bash
set -ex

# Don't allow the kernel to be updated
apt-mark hold linux-image-generic linux-headers-generic

# Don't allow the local installed packages to be updated
apt list --installed | grep "\[installed,local\]" | awk -F/ '{print $1}' | xargs apt-mark hold

# upgrade pre-installed components
apt update
apt upgrade -y

# jq is needed to parse the component versions from the versions.json file
ここから
#apt install -y jq