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
print_done

echo "CONTINUING WILL DESTROY ANY DATA ON THE TARGET INSTALLATION DISK"
read -p "Are you sure you want to continue (Y/N): " confirmation
if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
  echo "Understandable.  Ending installation attempt."
  exit 1
fi

echo "Creating partitions on $disk.."
# These are spammy so ignore their outputs
sgdisk --zap-all "$disk"
sgdisk --set-alignment=2048 --clear "$disk"
echo -n "Creating boot partition of size $boot_size.. "
sgdisk -n 1:0:+"$boot_size" -t 1:ef00 -c 1:"$boot_name" "$disk" > /dev/null
print_done

# Track root partition number, as it will be '2' without a swap partition, but 3 if one was created.
root_partition_num=2
if [ "$swap_type" == 'partition' ]; then
  echo -n "Creating swap partition of size $swap_size.. "
  sgdisk -n 2:0:+"$swap_size" -t 2:8200 -c 2:"$swap_name" "$disk" > /dev/null
  print_done
  root_partition_num=3
fi

echo -n "Creating root partition of size $root_size.. "
# If 'root_size' is 'fill' then change it to '0' which will have sgdisk fill all space
if [ "$root_size" == 'fill' ]; then root_size="0"; fi;
sgdisk -n "$root_partition_num":0:"$root_size" -t "$root_partition_num":8300 -c "$root_partition_num":"$root_name" "$disk" > /dev/null
print_done

echo "Creating filesystems.. "
# For NVME disks we need to insert a 'p' before the partition number, but not for others.
# eg.  /dev/nvme0n1p1 vs /dev/sda1
partition_char=""
if [[ "$disk" =~ 'nvme' ]]; then
  partition_char="p"
fi
mkfs.vfat -F 32 -n "$boot_name" "$disk$partition_char"1
mkfs.btrfs -f -L "$root_name" "$disk$partition_char$root_partition_num"
if [ "$swap_type" == 'partition' ]; then
  mkswap -L "$swap_name" "$disk$partition_char"2
fi