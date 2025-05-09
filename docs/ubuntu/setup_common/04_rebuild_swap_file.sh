#!/bin/bash
set -ex

# Rebuild swap file
swapoff -a
swapon --show
rm -fr /swap.img
fallocate -l 512M /swap.img
chmod 600 /swap.img
mkswap /swap.img
swapon -a