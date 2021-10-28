#!/usr/bin/env bash
#
# This script configures the system to be ready for running pacstrap.  This includes, but is not
# limited to, partitioning the disk, mounting partitions & selecting fast mirrors.
#

# Check network connectivity.  Assuming it's working if this script has been downloaded, but just in case..
echo -n "Checking for network connectivity..   "
if ping -q -c 1 -W 1 archlinux.org > /dev/null; then
  echo "Passed"
else
  echo "Failed.  Try using iwctl to configure your network."
  exit 1
fi

timedatectl set-ntp true
