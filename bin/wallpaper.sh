#!/usr/bin/env bash
# wallpaper.sh — pick a random wallpaper, set it in Sway, apply cwal colors
# Usage: wallpaper.sh [directory]   (default: ~/Pictures/Wallpapers)

set -euo pipefail

WALLPAPER_DIR="${1:-$HOME/Pictures/Wallpapers}"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Error: directory not found: $WALLPAPER_DIR" >&2
    exit 1
fi

wallpaper=$(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o \
    -iname "*.png" -o -iname "*.webp" \
\) | shuf -n 1)

if [[ -z "$wallpaper" ]]; then
    echo "Error: no images found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Write wallpaper path for sway to pick up on reload
echo "output * bg \"$wallpaper\" fill" > "$HOME/.config/sway/wallpaper.conf"

# Generate colors — cwal writes ~/.config/sway/colors.conf and runs swaymsg reload,
# which picks up the wallpaper change above at the same time.
cwal --img "$wallpaper"
