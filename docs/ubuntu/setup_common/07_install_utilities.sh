#!/bin/bash
set -ex

apt update

# Install common utilities
apt install -y -qq 7zip \
                   xz-utils \
                   bzip2 \
                   lz4 \
                   zip \
                   curl \
                   nfs-common \
                   rsync \
                   rclone \
                   at \
                   acl \
                   avahi-daemon \
                   screen \
                   pdsh

# Install prometheus-node-exporter
./07_01_install_prometheus.sh
