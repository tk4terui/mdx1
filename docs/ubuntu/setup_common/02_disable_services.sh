#!/bin/bash
set -ex

# Disable time synclonize
systemctl disable --now systemd-timesyncd.service
systemctl mask systemd-timesyncd.service

# Disable auto update services
sed -i 's/APT::Periodic::Unattended-Upgrade ".*/APT::Periodic::Unattended-Upgrade "0";/' /etc/apt/apt.conf.d/20auto-upgrades
sed -i 's/APT::Periodic::Update-Package-Lists ".*/APT::Periodic::Update-Package-Lists "0";/' /etc/apt/apt.conf.d/20auto-upgrades

systemctl disable --now unattended-upgrades.service
systemctl disable --now update-notifier-download.timer
systemctl mask unattended-upgrades.service
systemctl mask update-notifier-download.timer

# Disable cloud-init
systemctl disable --now cloud-init.service
systemctl mask cloud-init.service