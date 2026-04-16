#!/usr/bin/env bash
# install.sh — install all packages needed for MinimalOS

set -euo pipefail

echo "==> Installing pacman packages"
sudo pacman -S --needed \
    gnome-disk-utility \
    swaybg

echo ""
echo "==> Installing AUR packages (paru)"
paru -S --needed \
    brave-bin \
    visual-studio-code-bin

echo ""
echo "Done. All packages installed."
