#!/bin/bash
set -ex

# Remove snap packages
snap remove lxd
snap remove core20
snap remove snapd

# Remove snapd and cloud-init 
apt-get remove --auto-remove -y snapd cloud-init

# Remove x11 packages
apt-get remove --auto-remove -y 'x11-*'