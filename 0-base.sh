#!/usr/bin/env bash
#
# This script configures the system with the base system, ready to be arch-chrooted into to perform
# further setup.  This includes, but is not limited to, partitioning the disk, mounting partitions,
# selecting fast mirrors & running initial pacstrap.
#

cat <<EOM
===============================================
    0-base - Setting up base Arch system
===============================================
EOM

# Check network connectivity.  Assuming it's working if this script has been downloaded, but just in case..
echo -n "Checking for network connectivity..   "
if ping -q -c 1 -W 1 archlinux.org > /dev/null; then
  echo "Passed"
else
  echo "Failed.  Try using iwctl to configure your network."
  exit 1
fi

timedatectl set-ntp true

# After connecting to a network, the live ISO will automatically try to rank mirrors
# via a reflector systemd service.  If wait is enabled then hang until it is inactive.
until [ "$(systemctl is-active reflector.service)" = 'inactive' ]; do
  echo "Waiting for Reflector to finish ranking mirrors.."
  sleep 10
done
echo "Reflector has finished ranking mirrors!"


if [ "$disk" = 'prompt' ]; then
  cat <<EOM
-------------------------------
  Installation disk selection
-------------------------------
Showing list of disks to choose from..

EOM
  lsblk -p
  read -p "Enter the target installation disk: " disk
fi
# Ensure target disk exists
echo "Selected $disk as installation disk"
stat "$disk" | /dev/null