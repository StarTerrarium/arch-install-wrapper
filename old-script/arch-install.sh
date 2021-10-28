#!/bin/bash
# This is a super duper opinionated script to install Arch Linux from the live ISO.
# It is NOT a general purpose installer script.  Its only intention is to automate
# MY desired Arch setup, to aide me when I inevitably distro hop.

# By nature a script like this is DESTRUCTIVE.  Do not execute it randomly!

# Defaultable args.  Taking simple/naive approach of using an empty string to
# toggle optional behaviour, while others will have my personal defaults
WINDOWS_ESP_COPY=""
VERBOSE=false
ROOT_LABEL="arch_root"
BOOT_LABEL="arch_boot"
SWAP_LABEL="arch_swap"
BOOT_SIZE="512"
SWAP_SIZE="2"
EXTRA_PACKAGES=""
TIMEZONE="Australia/Melbourne"
LOCALES="en_US.UTF-8 en_AU.UTF-8 ja_JP.UTF-8"
DEFAULT_LANG="en_AU.UTF-8"
HOSTNAME="arch"
ROOT_PASS=""
USER=""
USER_PASS=""
MICROCODE="amd-ucode"
KERNEL_BOOT_ARGS="quiet splash"
REFLECTOR_WAIT=false

help() {
  cat <<EOM
Installs arch linux in an incredibly opinionated way.  Not too much is configurable.
Uses an entire disk with 3 partitions.  A 512M boot/esp, a 2G swap & the rest for root.
Root is ext4, boot is fat32
Systemd-boot is used for the bootloader.
Optional support for copying a Windows EFI from another partition

Required args:
-d DISK         Disk to install Arch onto (eg. /dev/sda)

Optional args:
-r LABEL        Label to attach to root partition & filesystem [Default:  $ROOT_LABEL]
-b LABEL        Label to attach to boot partition & filesystem [Default:  $BOOT_LABEL]
-s LABEL        Label to attach to swap partition & filesystem [Default:  $SWAP_LABEL]
-a SIZE         Boot partition size in Mebibytes - M/MiB [Default:  $BOOT_SIZE]
-e SIZE         Swap partition size in Gibibytes - G/GiB [Default:  $SWAP_SIZE]
-x PACKAGES     Extra packages to install during pacstrap [Default:  ${EXTRA_PACKAGES:-None}]
-t TIMEZONE     Timezone to configure. [Default:  $TIMEZONE]
-l LOCALES      Space seperated list of locales to generate. [Default:  $LOCALES]
-m LOCALE       Default language.  [Default:  $DEFAULT_LANG]
-n HOSTNAME     Hostname for the installed system.  [Default:  $HOSTNAME]
-p PASSWORD     Root password.  If unset, will prompt for input.  [Default:  Will prompt]
-u USERNAME     Admin (sudoer) user to create.  [Default:  ${USER:-Disabled}]
-y PASSWORD     Admin (sudoer) user password [Default:  Will prompt]
-c MICROCODE    CPU microcode package to install.  [Default:  $MICROCODE]
-k ARGS         Kernel boot arguments for bootloader configuraton  [Default:  $KERNEL_BOOT_ARGS]
-w PARTITION    Partition to copy Windows ESP config from (eg. /dev/nvme0n1p1) [Default:  ${WINDOWS_ESP_COPY:-Disabled}]
-q              Wait for reflector to rank mirrors before installing
-v              Verbose flag.  Sets -x if enabled.

EOM
}

check_required_args() {
  if [ -z "$TARGET_DISK" ]; then
    echo "Required option -d missing."
    exit 1
  fi
}

gen_target_partitions() {
  # For simplicity, limit support to sd* and nvme* targets.
  # nvme targets treated slightly differently as need to prepend a 'p' to the partition number
  if [[ "$TARGET_DISK" == *"nvme"* ]]; then
    ROOT_PARTITION="$TARGET_DISK"p1
    BOOT_PARTITION="$TARGET_DISK"p2
    SWAP_PARTITION="$TARGET_DISK"p3
  else
    ROOT_PARTITION="$TARGET_DISK"1
    BOOT_PARTITION="$TARGET_DISK"2
    SWAP_PARTITION="$TARGET_DISK"3
  fi
}

get_confirmation() {
  cat <<EOM
This script will attempt to install Arch Linux with the following configuration:
Install target disk..         $TARGET_DISK
Will create partitions..
    Root..                    $ROOT_PARTITION
    Boot..                    $BOOT_PARTITION
    Swap..                    $SWAP_PARTITION
Boot partition size..         $BOOT_SIZE MiB
Swap partition size..         $SWAP_SIZE GiB
Root filesystem label..       $ROOT_LABEL
Boot filesystem label..       $BOOT_LABEL
Swap filesystem label..       $SWAP_LABEL
Wait for reflector..          $REFLECTOR_WAIT
Extra packages to install..   ${EXTRA_PACKAGES:-None}
CPU microcode..               $MICROCODE
Timezone..                    $TIMEZONE
Locales..                     $LOCALES
Default lang..                $DEFAULT_LANG
Hostname..                    $HOSTNAME
Root user password..          $([ "$ROOT_PASS" ] && echo "Was supplied" || echo "Will prompt for input")
Non-root admin user..         ${USER:-Disabled}
Non-root user password..      $([ ! "$USER" ] && echo "Disabled" || ([ "$USER_PASS" ] && echo "Was supplied" || echo "Will prompt for input"))
Extra kernel boot args..      $KERNEL_BOOT_ARGS
Windows ESP copy partition..  ${WINDOWS_ESP_COPY:-Disabled}

EOM
  echo "WARNING:  This script is destructive.  Continuing will destroy data on the install target disk!"
  read -p "Continue (y/n)? " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^[yY]$ ]]; then
    echo "Understandable.  Have a nice day."
    exit 1
  fi
}

while getopts "hvd:r:b:s:a:e:x:t:l:m:n:p:c:k:w:u:y:q" option; do
  case $option in
    h) help; exit 0 ;;
    d) TARGET_DISK=$OPTARG ;;
    r) ROOT_LABEL=$OPTARG ;;
    b) BOOT_LABEL=$OPTARG ;;
    s) SWAP_LABEL=$OPTARG ;;
    a) BOOT_SIZE=$OPTARG ;;
    e) SWAP_SIZE=$OPTARG ;;
    x) EXTRA_PACKAGES=$OPTARG ;;
    t) TIMEZONE=$OPTARG ;;
    l) LOCALES=$OPTARG ;;
    m) DEFAULT_LANG=$OPTARG ;;
    n) HOSTNAME=$OPTARG ;;
    p) ROOT_PASS=$OPTARG ;;
    u) USER=$OPTARG ;;
    y) USER_PASS=$OPTARG ;;
    c) MICROCODE=$OPTARG ;;
    k) KERNEL_BOOT_ARGS=$OPTARG ;;
    w) WINDOWS_ESP_COPY=$OPTARG ;;
    q) REFLECTOR_WAIT=true ;;
    v) VERBOSE=true ;;
    *) echo "Unknown option $option" && help && exit 1 ;;
  esac
done

check_required_args
gen_target_partitions
get_confirmation


# Check network connectivity.  Assuming it's working if this script has been downloaded, but just in case..
echo -n "Checking for network connectivity..   "
if ping -q -c 1 -W 1 google.com > /dev/null; then
  echo "Passed"
else
  echo "Failed.  Try using iwctl to configure your network."
  exit 1
fi

if [ "$VERBOSE" = true ]; then
  # Make it clear what commands are running from this point
  set -x
fi

echo "Enabling time sync.."
timedatectl set-ntp true

echo "Creating partitions.."
# These are spammy so ignore their outputs
sgdisk --zap-all "$TARGET_DISK" > /dev/null
sgdisk -n 2:0:+"$BOOT_SIZE"M -t 2:ef00 -c 2:"$BOOT_LABEL" "$TARGET_DISK" > /dev/null
sgdisk -n 1:0:-"$SWAP_SIZE"G -t 1:8304 -c 1:"$ROOT_LABEL" "$TARGET_DISK" > /dev/null
sgdisk -n 3:0:0 -t 3:8200 -c 3:"$SWAP_LABEL" "$TARGET_DISK" > /dev/null

echo "Creating filesystems.."
mkfs.ext4 -L "$ROOT_LABEL" "$ROOT_PARTITION" > /dev/null
mkfs.fat -F 32 -n "$BOOT_LABEL" "$BOOT_PARTITION" > /dev/null
mkswap -L "$SWAP_LABEL" "$SWAP_PARTITION" > /dev/null

echo "Mounting filesystems.."
mount "$ROOT_PARTITION" /mnt
mkdir /mnt/boot
mount "$BOOT_PARTITION" /mnt/boot
swapon "$SWAP_PARTITION"

# After connecting to a network, the live ISO will automatically try to rank mirrors
# via a reflector systemd service.  If wait is enabled then hang until it is inactive.
if [ "$REFLECTOR_WAIT" = true ]; then
  until [ "$(systemctl is-active reflector.service)" = 'inactive' ]; do
    echo "Waiting for Reflector to finish ranking mirrors.."
    sleep 10
  done
  echo "Reflector has finished ranking mirrors!"
fi

echo "Installing the system.."
# Note the no quotes around EXTRA_PACKAGES, because word splitting is actually desired here.
pacstrap /mnt base base-devel linux linux-firmware dosfstools exfatprogs e2fsprogs ntfs-3g networkmanager vim man-db man-pages texinfo $MICROCODE $EXTRA_PACKAGES

echo "Generating fstab.."
genfstab -L /mnt >> /mnt/etc/fstab

# This part is interesting, because from here on we need to chroot into the environment - so what we actually need to do is generate a new script to be
# executed inside of this chroot.
cat > /mnt/chroot-install-script.sh <<EOM
#!/bin/bash
echo "Now executing inside the arch-chroot!"
if [ "$VERBOSE" = true ]; then
  # New shell, so I assume need to re-set this?
  set -x
fi

echo "Setting timezone.."
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

echo "Configuring RTC clock.."
hwclock --systohc

echo "Configuring locales.."
# Because all values in here will be templated out, we need to re-create the locales
# variable, and escape its usage.
TMP_LOCALES="$LOCALES"
for LOCALE in \$TMP_LOCALES; do
  sed -i "/^#\$LOCALE/s/^#//" /etc/locale.gen
done
locale-gen
echo "LANG=$DEFAULT_LANG" >> /etc/locale.conf

echo "Configuring hostname.."
echo "$HOSTNAME" >> /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME
EOF

echo "Setting root password.."
if [ "$ROOT_PASS" ]; then
  echo "root:$ROOT_PASS" | chpasswd
else
  passwd
fi

if [ "$USER" ]; then
  echo "Creating non-root user.."
  useradd -m -G wheel "$USER"
  if [ "$USER_PASS" ]; then
    echo "$USER:$USER_PASS" | chpasswd
  else
    passwd "$USER"
  fi
fi

/visudo-enable-wheel.sh

echo "Configuring bootloader.."
bootctl install

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$MICROCODE.img
initrd  /initramfs-linux.img
options root="LABEL=$ROOT_LABEL" rw $KERNEL_BOOT_ARGS
EOF

cat > /boot/loader/entries/arch-fallback.conf <<EOF
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /$MICROCODE.img
initrd  /initramfs-linux-fallback.img
options root="LABEL=$ROOT_LABEL" rw $KERNEL_BOOT_ARGS
EOF

cat > /boot/loader/loader.conf <<EOF
timeout      5
default      arch.conf
EOF

if [ "$WINDOWS_ESP_COPY" ]; then
  echo "Copying Windows ESP.."
  mount "$WINDOWS_ESP_COPY" /mnt
  cp -r /mnt/EFI/Microsoft /boot/EFI
  umount /mnt
fi

echo "Enabling NetworkManager systemd service.."
systemctl enable NetworkManager

echo "Completed arch-chroot configuration!"
EOM

# Generate a second script whose purpose is to edit the sudoers file via visudo to
# enable wheel group to use sudo
cat > /mnt/visudo-enable-wheel.sh <<EOM
#!/bin/bash
# This is a bit weird.  I want to go through visudo for correctness, but visudo
# is really built around interactive input, and I know I just want to enable the
# wheel group - just uncomment it.  Arch version of sudo is compiled with the
# '--with-env-editor' flag so we can make this script itself be the editor for
# visudo.  See this for the inspiration:  https://stackoverflow.com/a/3706774

# One difference is that with the version of visudo on my arch ISO, the $1 arg
# is "--" and $2 is the sudoers.tmp file.  Using -- is good practice, so I am
# just giving the whole $@ to the script.

# Also note the escaping of all the variables in this script.  Because it is
# generated by another script, they would be expanded by the parent script
# when being generated if not escaped.

if [ -z "\$1" ]; then
  EDITOR=\$0 visudo
else
  echo "Enabling sudo access for group 'wheel'.."
  # When invoked by visudo, \$@ will be something like "-- /etc/sudoers.tmp".
  # Note the lack of quotes around \$@, as word splitting is desired.
  sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' \$@
fi
EOM

echo "Executing arch-chroot to continue configuration.."
chmod +x /mnt/chroot-install-script.sh
chmod +x /mnt/visudo-enable-wheel.sh
arch-chroot /mnt /chroot-install-script.sh

echo "Now exited from arch-chroot and back to the live ISO environment!"

echo "Removing generated scripts from installed environment.."
rm /mnt/chroot-install-script.sh
rm /mnt/visudo-enable-wheel.sh

echo "Unmounting filesystems.."
umount -R /mnt

cat <<EOM
Installation complete!
It should be safe to reboot the fresh Arch installation now!

For wireless networks, remember to use nmtui or nmcli to connect again.
EOM