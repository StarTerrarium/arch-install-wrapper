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
echo -n "Checking for network connectivity.. "
if ping -q -c 1 -W 1 archlinux.org > /dev/null; then
  print_done
else
  fail "Try using iwctl to configure your network."
fi

timedatectl set-ntp true

# After connecting to a network, the live ISO will automatically try to rank mirrors
# via a reflector systemd service.  If wait is enabled then hang until it is inactive.
echo -n "Waiting for Reflector to finish ranking mirrors.. "
until [ "$(systemctl is-active reflector.service)" = 'inactive' ]; do
  sleep 10
  echo
  echo -n "Waiting for Reflector to finish ranking mirrors.. "
done
print_done


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
echo -n "Checking that $disk exists.. "
stat "$disk" > /dev/null 2>&1 || fail "$disk was not found with 'stat' command, ensure you entered the correct path."
echo "DONE"
echo "CONTINUING WILL DESTROY ANY DATA ON THE TARGET INSTALLATION DISK"
read -p "Are you sure you want to continue (Y/N): " confirmation
if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
  echo "Understandable.  Ending installation attempt."
  exit 1
fi

echo "Creating partitions on $disk.."
