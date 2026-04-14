#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – Randomize Wallpaper
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

CONFIG_FILE="${MINIMALOS_CONF:-/etc/minimalos/minimalos.conf}"
[ ! -f "$CONFIG_FILE" ] && echo "Missing config: $CONFIG_FILE" && exit 1
source "$CONFIG_FILE"

mkdir -p "$WALLPAPER_DIR"
sudo mkdir -p "$(dirname "$CURRENT_WALLPAPER")"
sudo chown -R "$USER:$USER" "$(dirname "$CURRENT_WALLPAPER")"

# Pick a random wallpaper
SELECTED=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [ -z "$SELECTED" ]; then
    SELECTED=$(find /usr/share/backgrounds -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
fi

if [ -z "$SELECTED" ]; then
    notify-send -a "MinimalOS" "No wallpapers found" -u critical
    exit 1
fi

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

notify-send -a "MinimalOS" "Wallpaper" "Randomized & colors updated" -t 2000
