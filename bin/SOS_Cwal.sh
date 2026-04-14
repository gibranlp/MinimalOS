#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS – cwal Theme Manager
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence

CONFIG_FILE="${MINIMALOS_CONF:-/etc/minimalos/minimalos.conf}"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

ROFI_THEME="$HOME/.config/rofi/SOS_Left.rasi"

# ── Helpers ──────────────────────────────────────────────────────────────
current_setting() {
    local key="$1"
    grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'"' -f2
}

update_setting() {
    local key="$1" val="$2"
    sudo sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$CONFIG_FILE"
}

notify() {
    notify-send -a "MinimalOS" "$1" "$2"
}

# ── Re-apply Colors ───────────────────────────────────────────────────────
apply_cwal() {
    local wall="${1:-$CURRENT_WALLPAPER}"
    [ ! -f "$wall" ] && notify "cwal" "No wallpaper found at $wall" && return 1

    cwal --img "$wall" \
         --mode "$CWAL_MODE" \
         --backend "$CWAL_BACKEND" \
         --saturation "$CWAL_SATURATION" \
         --contrast "$CWAL_CONTRAST" \
         --alpha "$CWAL_ALPHA" \
         --quiet

    notify "Theme Applied" "Colors updated from wallpaper"
}

# ── Toggle Dark / Light ───────────────────────────────────────────────────
toggle_mode() {
    local current
    current=$(current_setting "CWAL_MODE")
    local new_mode
    if [ "$current" = "dark" ]; then
        new_mode="light"
    else
        new_mode="dark"
    fi
    update_setting "CWAL_MODE" "$new_mode"
    source "$CONFIG_FILE"
    apply_cwal
    notify "Theme Mode" "Switched to ${new_mode^}"
}

# ── Set Backend ───────────────────────────────────────────────────────────
set_backend() {
    local current
    current=$(current_setting "CWAL_BACKEND")
    local backends=("cwal" "libimagequant" "imagemagick")
    local options=""
    for b in "${backends[@]}"; do
        [ "$b" = "$current" ] && options+="${b} (current)\n" || options+="${b}\n"
    done

    local selected
    selected=$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" \
               -p " Backend: ")
    [ -z "$selected" ] && return
    selected="${selected/ (current)/}"

    update_setting "CWAL_BACKEND" "$selected"
    source "$CONFIG_FILE"
    apply_cwal
}

# ── Set Saturation ────────────────────────────────────────────────────────
set_saturation() {
    local current
    current=$(current_setting "CWAL_SATURATION")
    local levels=("0.0 (natural)" "0.1" "0.2" "0.3" "0.4" "0.5" "0.6" "0.7" "0.8" "0.9" "1.0 (vivid)")
    local options=""
    for l in "${levels[@]}"; do
        local val="${l%% *}"
        [ "$val" = "$current" ] && options+="${l} ◄\n" || options+="${l}\n"
    done

    local selected
    selected=$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" \
               -p " Saturation (current: ${current}): ")
    [ -z "$selected" ] && return
    local new_val="${selected%% *}"

    update_setting "CWAL_SATURATION" "$new_val"
    source "$CONFIG_FILE"
    apply_cwal
}

# ── Set Alpha ─────────────────────────────────────────────────────────────
set_alpha() {
    local current
    current=$(current_setting "CWAL_ALPHA")
    local levels=("0.7" "0.75" "0.8" "0.85" "0.9" "0.95" "1.0 (opaque)")
    local options=""
    for l in "${levels[@]}"; do
        local val="${l%% *}"
        [ "$val" = "$current" ] && options+="${l} ◄\n" || options+="${l}\n"
    done

    local selected
    selected=$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" \
               -p " Alpha (current: ${current}): ")
    [ -z "$selected" ] && return
    local new_val="${selected%% *}"

    update_setting "CWAL_ALPHA" "$new_val"
    source "$CONFIG_FILE"
    apply_cwal
}

# ── Main Menu ─────────────────────────────────────────────────────────────
main_menu() {
    source "$CONFIG_FILE"
    local mode_label
    [ "$CWAL_MODE" = "dark" ] && mode_label=" Dark Mode" || mode_label=" Light Mode"

    local options=(
        " Re-apply Colors"
        "${mode_label} (toggle)"
        " Set Backend (${CWAL_BACKEND})"
        " Set Saturation (${CWAL_SATURATION})"
        " Set Alpha (${CWAL_ALPHA})"
    )

    local choice
    choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu -theme "$ROFI_THEME" \
             -p " cwal Theme")
    [ -z "$choice" ] && exit 0

    case "$choice" in
        " Re-apply Colors")         apply_cwal ;;
        *"toggle"*)                  toggle_mode ;;
        " Set Backend"*)            set_backend ;;
        " Set Saturation"*)         set_saturation ;;
        " Set Alpha"*)              set_alpha ;;
    esac
}

main_menu
