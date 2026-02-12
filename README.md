# Volume Pulse

Volume Pulse is a lightweight volume control utility for Linux systems. It runs in the system tray and allows you to control your audio output using mouse scroll, tray icon clicks, or your system’s volume keys. Volume Pulse is written in (C & Crystal) and uses the GTK2 toolkit for its graphical interface.

## Features

* Tray icon with real-time volume status
* Mouse scroll support to increase/decrease volume
* Left click to toggle mute
* Middle click can be set to open a mixer or mute
* Optional notification popups
* Volume shortcuts support (XF86 keys)
* Simple config file for customization

## Installation

### Requirements

* `pulseaudio`
* `pavucontrol` (for mixer)
* `libnotify`
* `libgtk-2-dev | gtk2`
* `libfm-gtk2` (for lxde)

### Using AUR

```bash
paru -S volume-pulse
# or
yay -S volume-pulse
```
#### Manual Installation
```bash
git clone https://aur.archlinux.org/volume-pulse.git
cd volume-pulse
makepkg -si
```

### Using the installer script

```bash
chmod a+x install.sh
./installer.sh install crystal
# OR
./installer.sh install c 
```

To uninstall:

```bash
./installer.sh uninstall
```

## Usage

```bash
volume-pulse &
```

## Configuration

Edit `~/.config/volume-pulse/config.conf` to customize behavior.

Example config:

```ini
volume_increase = 5
max_volume = 200%

# "false", "mixer", "mute"
middle_click_action = mixer

mixer = pavucontrol

use_notifications = false

# Enable keyboard shortcuts (X11 only)
use_shortcuts = true

use_arguments = true

```

## CLI Options

You can also control the volume from the terminal (best option for custom shortcuts):

```bash
volume-pulse -u   # Volume up
volume-pulse -d   # Volume down
volume-pulse -m   # Toggle mute
volume-pulse -s   # Show volume level
volume-pulse -v   # Version info
```

## Contributing

1. Fork it (<https://github.com/VC365/volume-pulse/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [VC365](https://github.com/VC365) - creator and maintainer
