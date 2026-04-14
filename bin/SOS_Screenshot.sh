#!/usr/bin/env bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – Screenshot (X11: maim + xdotool)
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

ROFI_THEME="$HOME/.config/rofi/SOS_Right.rasi"
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

OPTIONS=" Area\n Screen\n Window\n 5s Delay"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu \
    -theme "$ROFI_THEME" \
    -p " Screenshot" \
    -lines 4)

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    " Area")
        FILE="$SCREENSHOT_DIR/area_${TIMESTAMP}.png"
        maim --select "$FILE" && \
            xclip -selection clipboard -t image/png < "$FILE" && \
            notify-send -a "Screenshot" "Area saved & copied" -i "$FILE" -t 3000
        ;;

    " Screen")
        FILE="$SCREENSHOT_DIR/screen_${TIMESTAMP}.png"
        sleep 0.3
        maim "$FILE" && \
            xclip -selection clipboard -t image/png < "$FILE" && \
            notify-send -a "Screenshot" "Screen saved & copied" -i "$FILE" -t 3000
        ;;

    " Window")
        FILE="$SCREENSHOT_DIR/window_${TIMESTAMP}.png"
        WIN_ID=$(xdotool getactivewindow)
        sleep 0.2
        maim --window "$WIN_ID" "$FILE" && \
            xclip -selection clipboard -t image/png < "$FILE" && \
            notify-send -a "Screenshot" "Window saved & copied" -i "$FILE" -t 3000
        ;;

    " 5s Delay")
        FILE="$SCREENSHOT_DIR/screen_${TIMESTAMP}.png"
        notify-send -a "Screenshot" "Taking screenshot in 5s…" -t 4500
        sleep 5
        maim "$FILE" && \
            xclip -selection clipboard -t image/png < "$FILE" && \
            notify-send -a "Screenshot" "Saved & copied" -i "$FILE" -t 3000
        ;;

    *)
        exit 0
        ;;
esac
