# Volume Pulse

Volume Pulse is a lightweight volume control utility for Linux systems. It runs in the system tray and allows you to control your audio output using mouse scroll, tray icon clicks, or your system’s volume keys. Volume Pulse is written in C and uses the GTK2 toolkit for its graphical interface.

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

* A GTK-based desktop environment
* `pulseaudio`
* `pavucontrol` (for mixer)
* `libnotify`
* `libgtk-2-dev`

### Using the installer script

```bash
chmod a+x install.sh
./install.sh install
```

This installs the binary to `/usr/bin/volume-pulse` and sets up the config file at `~/.config/volume-pulse/config.conf`.

To uninstall:

```bash
./install.sh uninstall
```

## Usage

Once installed, just run:

```bash
volume-pulse &
```

It will start in the system tray.

## Configuration

Edit `~/.config/volume-pulse/config.conf` to customize behavior.

Example config:

```ini
volume_increase = 5
max_volume = 200%

middle_click_action = mixer
mixer = pavucontrol

use_notifications = false
use_shortcuts = false
```

## CLI Options

You can also control volume from terminal:

```bash
volume-pulse -u   # Volume up
volume-pulse -d   # Volume down
volume-pulse -m   # Toggle mute
volume-pulse -s   # Show volume level
volume-pulse -v   # Version info
```

## License

Proprietary. All rights reserved.

## Author

[VC365](https://github.com/VC365)
