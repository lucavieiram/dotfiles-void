#!/usr/bin/env bash
# lock-now.sh — gtklock with blurred current wallpaper + big clock.
# Bound to Super+L. Also invoked by swayidle (autostart).

set -euo pipefail

# Avoid double-lock if already running
pgrep -x gtklock >/dev/null && exit 0

WP="$HOME/Pictures/Wallpapers/current.png"
BG="${XDG_RUNTIME_DIR:-/tmp}/lock-bg.png"
STYLE="$HOME/.config/gtklock/style.css"

# Regenerate blurred background only if wallpaper is newer (cheap on repeat locks)
if [ ! -f "$BG" ] || [ "$WP" -nt "$BG" ]; then
    convert "$WP" -resize 1920x1080^ -gravity center -extent 1920x1080 \
            -blur 0x18 -modulate 65,100,100 "$BG"
fi

exec gtklock \
    --daemonize \
    --background "$BG" \
    --style "$STYLE" \
    --time-format "%H:%M" \
    --date-format "%A, %d de %B"
