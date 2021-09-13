# Things I sometimes do after an install

This file is largely just to document for myself some things I frequently do after an install so that I don't need to keep referring
to the arch wiki - although checking it occassionally to remain up to date is a good idea.

### Network

NetworkManager is installed.  Use `nmtui` to connect to a wireless network if required.

### Desktop Environment

Generally I use KDE plasma.  See https://wiki.archlinux.org/title/KDE

Although I use Wayland where possible, still requires Xorg for now.  Also SDDM (plasma default session manager) still doesn't run on Wayland.

Install plasma & all its bulk (see above link for how to install more minimal version).  Then enable sddm.

```
sudo pacman -S xorg-server xorg-apps plasma plasma-wayland-session kde-applications
systemctl enable sddm
```

Apparently Pipewire is the default now for plasma!  So no Pipewire configuration needed.  Reboot and login to the shiny new plasma environment.
