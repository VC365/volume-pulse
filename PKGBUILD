# Contributor: VC365
pkgname=volume-pulse
pkgver=0.1.0
pkgrel=2
pkgdesc="A lightweight volume control utility for Linux"
arch=('x86_64')
url="https://github.com/VC365/volume-pulse"
license=('Proprietary')
depends=('pulseaudio' 'libnotify' 'gtk2')
makedepends=('git')
optdepends=('pavucontrol: For mixer functionality')
source=("git+https://github.com/VC365/volume-pulse.git#tag=v$pkgver")
sha256sums=('SKIP')

DIR_CONFIG="$HOME/.config/volume-pulse"

read -r -d '' config << 'EOF'
volume_increase = 5
max_volume = 200%

# "false", "mixer", "mute"
middle_click_action = mixer

mixer = pavucontrol

use_notifications = false

use_shortcuts = false
EOF

package() {
  cd "$srcdir/volume-pulse"
    if [ ! -f volume-pulse ]; then
        echo -e "${RED} volume-pulse not found in current directory!${NC}"
        exit 1
    fi
    mkdir -p "$DIR_CONFIG"
	if [ ! -f "$DIR_CONFIG/config.conf" ]; then
      echo "$config" > "$DIR_CONFIG/config.conf"
	fi
	  install -Dm755 volume-pulse "$pkgdir"/usr/bin/volume-pulse
}

post_install() {
  echo "Volume Pulse installed successfully."
}

post_remove() {
  echo "Removing volume-pulse..."
  
  rm -f "$pkgdir/usr/bin/volume-pulse"
  
  echo "volume-pulse deleted!"
}
    
