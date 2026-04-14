#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – Session Manager
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

options=(
    " Lock"
    " Suspend"
    "󰗼 Logout"
    " Reboot"
    " Poweroff"
)

choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu \
    -theme ~/.config/rofi/SOS_Right.rasi \
    -p " Session")

[ -z "$choice" ] && exit 0

case "$choice" in
    " Lock")
        # Lock with a color pulled from cwal palette
        BG=$(grep "^export color0=" ~/.cache/cwal/colors.sh 2>/dev/null | cut -d"'" -f2 | tr -d '#')
        BG="${BG:-1a1a2e}"
        i3lock -c "$BG"
        ;;
    " Suspend")
        systemctl suspend
        ;;
    "󰗼 Logout")
        # Gracefully exit AwesomeWM
        echo 'awesome.quit()' | awesome-client 2>/dev/null || pkill awesome
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Poweroff")
        systemctl poweroff
        ;;
esac
