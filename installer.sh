#!/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
DIR_APP="/usr/bin"
DIR_CONFIG="$HOME/.config/volume-pulse"

read -r -d '' config << 'EOF'
volume_increase = 5
max_volume = 200%

middle_click_action = mixer

mixer = pavucontrol

use_notifications = false

use_shortcuts = true

use_arguments = true

EOF
install() {
    echo -e "${YELLOW}installing volume-pulse...${NC}"
    if [ ! -f volume-pulse ]; then
        echo -e "${RED} volume-pulse not found in current directory!${NC}"
        exit 1
    fi
    mkdir -p "$DIR_CONFIG"
	if [ ! -f "$DIR_CONFIG/config.conf" ]; then
      echo "$config" > "$DIR_CONFIG/config.conf"
	fi
	if [ -f "$DIR_APP/volume-pulse" ]; then
	    sudo rm "$DIR_APP/volume-pulse"
	fi
	chmod a+x volume-pulse
	sudo cp volume-pulse "$DIR_APP"
	echo -e "${GREEN} volume-pulse Installed!${NC}"
}

uninstall() {
    sudo rm -f "$DIR_APP/volume-pulse" &> /dev/null
    echo -e "${GREEN} volume-pulse Deleted!${NC}"
}

if [ "$1" == "install" ]; then
    install
elif [ "$1" == "uninstall" ]; then
    uninstall
else
    echo -e "${RED} Options $0 {install|uninstall}${NC}"
    exit 1
fi
