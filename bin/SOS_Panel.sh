#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – Control Panel
# Central hub replacing a status bar. Launch with Mod+P.
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

ROFI_THEME="$HOME/.config/rofi/SOS_Left.rasi"
BIN="$HOME/.local/bin"

options=(
    " App Launcher (Mod+D)"             #0
    " App Launcher as Root"             #1
    ""                                  #2
    " Wallpaper Options"                #3
    "    Randomize (Mod+R)"             #4
    "    Select (Mod+W)"                #5
    ""                                  #6
    " cwal Theme"                       #7
    "    Re-apply Colors"               #8
    "    Theme Settings"                #9
    ""                                  #10
    " Tools"                            #11
    "    Search Files (Mod+S)"          #12
    "    Calculator (Mod+C)"            #13
    "    WiFi (Mod+B)"                  #14
    "    Bluetooth (Mod+⇧+B)"          #15
    "    Password Generator (Mod+G)"    #16
    "    Screenshot (PrtSc)"            #17
    "    Power Profile (Mod+E)"         #18
    "    System Cleaner"                #19
    "    Update System"                 #20
    "    Monitor (btop)"                #21
    "    Pick Color"                    #22
    "    Emoji Picker"                  #23
    ""                                  #24
    " Session (Mod+X)"                  #25
)

choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu -i \
    -theme "$ROFI_THEME" \
    -p " MinimalOS")

index=$(printf "%s\n" "${options[@]}" | grep -nxF "$choice" | cut -d: -f1)
index=$((index - 1))

[ -z "$choice" ] && exit 0

case $index in
    0) rofi -show drun -show-icons -theme "$HOME/.config/rofi/SOS_Left.rasi" ;;
    1) rofi -show drun -run-command "pkexec {cmd}" -theme "$HOME/.config/rofi/SOS_Left.rasi" ;;
    4) "$BIN/SOS_Randomize_Wallpaper.sh" ;;
    5) "$BIN/SOS_Select_Wallpaper.sh" ;;
    8)
        CONFIG_FILE="${MINIMALOS_CONF:-/etc/minimalos/minimalos.conf}"
        [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
        [ -f "$CURRENT_WALLPAPER" ] && \
            cwal --img "$CURRENT_WALLPAPER" --quiet && \
            notify-send -a "MinimalOS" "Colors re-applied"
        ;;
    9)  "$BIN/SOS_Cwal.sh" ;;
    12) "$BIN/SOS_Search.sh" ;;
    13) "$BIN/SOS_Calculator.sh" ;;
    14) "$BIN/SOS_Wifi.sh" ;;
    15) "$BIN/SOS_Bluetooth.sh" ;;
    16) "$BIN/SOS_Pass_Generator.sh" ;;
    17) "$BIN/SOS_Screenshot.sh" ;;
    18) "$BIN/SOS_Power.sh" ;;
    19) "$BIN/SOS_CleanSystem.sh" ;;
    20) "$BIN/SOS_UpdateBase.sh" ;;
    21) alacritty -e btop ;;
    22)
        sleep 0.2
        COLOR=$(xcolor -f '#%02x%02x%02x')
        [ -n "$COLOR" ] && echo -n "$COLOR" | xclip -selection clipboard && \
            notify-send -a "MinimalOS" "Color Picked" "$COLOR"
        ;;
    23) rofi -modi emoji -show emoji -theme "$HOME/.config/rofi/SOS_Left.rasi" ;;
    25) "$BIN/SOS_Session.sh" ;;
esac
