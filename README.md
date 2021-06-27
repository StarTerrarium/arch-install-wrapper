# Arch Install Wrapper

My personal Arch Linux install script.  It takes an opinionated approach to installing Arch, with some moderate
ability to configure things.  It is not intended to be general purpose - I'll likely just add to it when I
need my own features added.

## Target System Configuration

This is an opinionated Arch Linux configuration - but what does it actually do?

* Creates 3 partitions using an entire disk.  One each for root, boot & swap.
* Boot & swap size are configurable, while root will use up all remaining space.
* Root is ext4, boot is fat32.
* fstab uses labels instead of UUID.
* NetworkManager is installed & enabled.
* systemd-boot is used for the bootloader.
* The 'wheel' group is enabled for sudo.

## Configurations

There is some amount of customisation you can do by supplying different arguments.  They are:

| Flag                   | Required | Description                                                                                                                                                                                                                                  |
|------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| -d <path-to-device>    | Yes      | Target device to install Arch Linux onto.  For example /dev/sda                                                                                                                                                                              |
| -r <label>             | No       | Label to attach to the root partition & filesystem.  **[Default:  arch_root]**                                                                                                                                                               |
| -b <label>             | No       | Label to attach to the boot partition & filesystem.  **[Default:  arch_boot]**                                                                                                                                                               |
| -s <label>             | No       | Label to attach to the root partition & filesystem.  **[Default:  arch_swap]**                                                                                                                                                               |
| -a <size-in-MiB>       | No       | Boot partition size in MiB. **[Default: 512]**                                                                                                                                                                                               |
| -e <size-in-GiB>       | No       | Swap partition size in GiB. **[Default: 2]**                                                                                                                                                                                                 |
| -x <packages>          | No       | Extra packages to install during pacstrap.  If more than one,  ensure this arg is wrapped in quotes, and packages are space separated. **[Default: "quiet splash"]**                                                                         |
| -t <timezone>          | No       | Timezone to configure. **[Default: Australia/Melbourne]**                                                                                                                                                                                    |
| -l <locales>           | No       | Locales to enable & generate.  If more than one, ensure this arg is wrapped in quotes, and locales are space separated. **[Default: "en_US.UTF-8 en_AU.UTF-8 ja_JP.UTF-8"]**                                                                 |
| -m <locale>            | No       | Default system language. **[Default: en_AU.UTF-8]**                                                                                                                                                                                          |
| -n <hostname>          | No       | Hostname for the system. **[Default: arch]**                                                                                                                                                                                                 |
| -p <password>          | No       | Password to set for the root user.  If not supplied the script will prompt for input during installation. **[Default: Prompt for input]**                                                                                                    |
| -u <username>          | No       | Create an admin (sudoer) user with the given username.  If not supplied no user is created. **[Default:  No admin user created]**                                                                                                            |
| -y <password>          | No       | Password to set for the admin (sudoer) user.  If not supplied the script will prompt for input during installation. **[Default: Prompt for input]**                                                                                          |
| -c <microcode-package> | No       | CPU microcode package to install & configure in bootloader. **[Default: amd-ucode]**                                                                                                                                                         |
| -k <kernel-args>       | No       | Kernel boot arguments for bootloader configuration.  If more than one,  ensure this arg iswrapped in quotes, and locales are space separated. **[Default: "quiet splash"]**                                                                  |
| -w <path-to-partition> | No       | To copy a Windows ESP configuration.  If supplied the script will mount this partition and copy the Microsoft configuration to the ESP of the target Arch Linux device.  See the [dual-booting Windows](#dual-booting-windows) section of the readme. **[Default: Disabled]** |
| -q                     | No       | If enabled, forces the script to wait for Reflector to finish ranking mirrors before performing the pacstrap installation. **[Default: Disabled]**                                                                                           |
| -v                     | No       | Verbose mode.  If enabled the script will execute with 'set -x' enabled. **[Default: Disabled]**                                                                                                                                             |

## Usage

After booting into the Arch Linux live ISO connect to a network if required, download the script, and execute it. 

```bash
# For wireless connectivity
iwctl station list # Find your station ID
iwctl station <station> connect <SSID>

# Download the script
curl -o install.sh https://raw.githubusercontent.com/Wrayos/arch-install-wrapper/v0.0.1/arch-install.sh

# Execute the script.  -d is the only required argument.
chmod +x script.sh
./script.sh -d <target device>
```

And my usage:

```bash
iwctl station wlan0 connect MySSID
# Interactive step to supply WiFi password

curl -o install.sh https://raw.githubusercontent.com/Wrayos/arch-install-wrapper/v0.0.1/arch-install.sh
chmod +x install.sh
./install.sh -q -d /dev/sda -w /dev/nvme0n1p1 -u wrayos -x "cowsay neofetch" # Very important packages!
# Two interactive steps during install to set root & admin user passwords
reboot
```

## Dual-booting Windows

How Windows handles its ESP can be mildly annoying if you're like me and distrohop all the damn time (thus the reason
this script exists).

When installing Windows, if it detects an existing ESP on the system, it will install its own boot configuration onto
that ESP.  That's fine for a lot of use-cases and probably a good default - I just wish it would let me choose.  The
problem I face with this approach is that it installs onto my Linux drive, and I routinely wipe & reinstall over that
entire disk - causing me to lose the Windows bootloader!

My solution to this is to have two disks - one dedicated for Windows, and one dedicated for Linux.  When installing
Windows I ensure that _only_ its disk is attached, so it can't decide to install its bootloader to the Linux disk ESP.

This result is that I end up with two ESPs on my system - which is fine.  If using GRUB it is able to search all ESPs
on the system and locate Windows, even if it's on another disk.  Unfortunately systemd-boot does not do this.  It can
automatically add a Windows entry, but only if it's on the same ESP as systemd-boot.

The workaround I use for this is to _copy_ the Windows bootloader from its ESP onto the Linux ESP.  This way,
systemd-boot can boot Windows, but if I nuke the Linux drive I still have the original Windows bootloader to fallback
on.

This installer script supports this workaround by its `-w <partition>` flag.  If supplied it will mount that partition
and copy the directory at `<partition-mount>/EFI/Microsoft` to `/boot/EFI`.