# Things I sometimes do after an install

This file is largely just to document for myself some things I frequently do after an install so that I don't need to keep referring
to the arch wiki - although checking it occassionally to remain up to date is a good idea.

### Network

NetworkManager is installed.  Use `nmtui` to connect to a wireless network if required.

### Desktop Environment

Generally I use KDE plasma.  See https://wiki.archlinux.org/title/KDE

Although I use Wayland where possible, still requires Xorg for now.  Also SDDM (plasma default session manager) still doesn't run on Wayland.

Install plasma & all its bulk (see above link for how to install more minimal version).  Then enable sddm.  Also just get Firefox, need a browser always.

```
sudo pacman -S xorg-server xorg-apps plasma plasma-wayland-session kde-applications firefox
systemctl enable sddm
```

Apparently Pipewire is the default now for plasma!  So no Pipewire configuration needed.  Reboot and login to the shiny new plasma environment.

### Japanese fonts & input

The install script defaults to building the japanese locale, but to actually render with nice fonts, and input, there's some more configuration to be done.
To be honest I've never had configuring input go smoothly on KDE and just always eventually end up in an acceptable spot - so this time I'm documenting it.

First is fonts.  Just install noto cjk fonts.  Trust me.  Restart firefox/any apps afterwards to have them use the new fonts.

```
sudo pacman -S noto-fonts-cjk
```

Now let's configure fcitx5.  Install the fcitx5-im group which will pull in fcitx5, qt & gtk plugins, and the configuration tool.  We'll also grab the mozc
package and use that for Japanese

```
sudo pacman -S fcitx5-im fcitx5-mozc
```

Configure some global environment variables so fcitx is always used with `sudo vim /etc/environment` and enter
```
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
```

Go ahead and restart now for safety & consistency.  fcitx5 should autostart with plasma.

Once started up again, open the configtool by right clicking the keyboard icon in the system tray, hit configure.
I had a weird issue where the `+ Add Input Method...` button (and 2 other buttons) were not visible in the window until I resized it.  Odd.
Hit that Add Input method button, search for `mozc` and add it.  Click apply.
Now hitting `ctrl + space` should switch to mozc & ひらがな input - test it in the test box.

So that should be a good basic setup all working now.  Configure mozc itself to change how things are typed (eg direct kana input with a japanese keyboard, instead of romaji/phonetic input). 
