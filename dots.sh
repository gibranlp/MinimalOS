#!/usr/bin/env bash
# dots.sh — copy dotfiles from this repo to their ~/.config locations

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

deploy() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp -v "$src" "$dst"
}

echo "==> Deploying dotfiles from $REPO"

# Alacritty
deploy "$REPO/alacritty/alacritty.toml"   "$HOME/.config/alacritty/alacritty.toml"

# Sway
deploy "$REPO/sway/config"                              "$HOME/.config/sway/config"
deploy "$REPO/sway/config.d/50-systemd-user.conf"      "$HOME/.config/sway/config.d/50-systemd-user.conf"
# Only deploy the fallback wallpaper.conf if one doesn't already exist
[[ ! -f "$HOME/.config/sway/wallpaper.conf" ]] && \
    deploy "$REPO/sway/wallpaper.conf" "$HOME/.config/sway/wallpaper.conf"

# cwal — config
deploy "$REPO/cwal/cwal.ini"              "$HOME/.config/cwal/cwal.ini"

# cwal — templates (go to XDG data dir, not config)
deploy "$REPO/cwal/templates/colors-alacritty.toml"   "$HOME/.local/share/cwal/templates/colors-alacritty.toml"
deploy "$REPO/cwal/templates/colors-sway.conf"        "$HOME/.local/share/cwal/templates/colors-sway.conf"

# bin — scripts go to ~/.local/bin (make sure it's in your PATH)
deploy "$REPO/bin/wallpaper.sh"   "$HOME/.local/bin/wallpaper.sh"
chmod +x "$HOME/.local/bin/wallpaper.sh"

echo ""
echo "Done."
echo "  - Run 'wallpaper.sh' to set a random wallpaper and apply cwal colors"
echo "  - Run 'wallpaper.sh ~/some/dir' to use a different wallpaper directory"
echo "  - Alacritty picks up colors from ~/.cache/cwal/colors-alacritty.toml"
echo "  - Sway reloads colors automatically via ~/.config/sway/colors.conf"
