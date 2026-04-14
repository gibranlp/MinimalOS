#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – Select Wallpaper
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

CONFIG_FILE="${MINIMALOS_CONF:-/etc/minimalos/minimalos.conf}"
[ ! -f "$CONFIG_FILE" ] && echo "Missing config: $CONFIG_FILE" && exit 1
source "$CONFIG_FILE"

if [ -z "$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null)" ]; then
    notify-send -a "MinimalOS" "No wallpapers found in $WALLPAPER_DIR" -u critical
    exit 1
fi

# Select wallpaper via rofi filebrowser
SELECTED=$(rofi \
    -show filebrowser \
    -filebrowser-directory "$WALLPAPER_DIR" \
    -filebrowser-command "echo" \
    -theme "$HOME/.config/rofi/SOS_Wallpaper.rasi" \
    -filebrowser-sorting-method mtime \
    -filebrowser-show-hidden false \
    -filebrowser-disable-status true \
    -p "  Wallpaper")

[ -z "$SELECTED" ] && exit 0

# Copy to current wallpaper slot
cp "$SELECTED" "$CURRENT_WALLPAPER"
echo "$CURRENT_WALLPAPER" | sudo tee /var/lib/minimalos/current_wallpaper > /dev/null

# Apply wallpaper
feh --bg-scale "$CURRENT_WALLPAPER"

# Apply colors with cwal
cwal --img "$CURRENT_WALLPAPER" \
     --mode "$CWAL_MODE" \
     --backend "$CWAL_BACKEND" \
     --saturation "$CWAL_SATURATION" \
     --contrast "$CWAL_CONTRAST" \
     --alpha "$CWAL_ALPHA" \
     --quiet

notify-send -a "MinimalOS" "Wallpaper" "Applied & colors updated" \
            -i "$CURRENT_WALLPAPER" -t 2000
