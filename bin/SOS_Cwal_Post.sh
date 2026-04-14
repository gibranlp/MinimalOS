#!/bin/bash
# MinimalOS – cwal Post-Processing Script
# Runs automatically after cwal applies colors.
# Referenced in configs/cwal/cwal.ini as script_path.
# ─────────────────────────────────────────────────────────────────────────────

# Reload AwesomeWM (picks up new border/accent colors from colors.sh)
if pgrep -x awesome > /dev/null; then
    echo 'awesome.restart()' | awesome-client 2>/dev/null
fi

# Picom doesn't need a reload for colors, but restart if config changed
# pkill picom; picom --config ~/.config/picom/picom.conf -b &

# Update xrdb with cwal Xresources (if template is linked)
[ -f ~/.cache/cwal/colors.Xresources ] && xrdb -merge ~/.cache/cwal/colors.Xresources
