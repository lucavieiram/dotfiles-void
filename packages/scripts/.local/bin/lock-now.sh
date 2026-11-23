#!/usr/bin/env bash
# lock-now.sh — lock the session. Bound to Super+L; also run by swayidle (idle, before-sleep, lock).
# Uses the Quickshell lock screen (packages/quickshell/lock); falls back to gtklock if qs is not
# running or does not answer.

set -euo pipefail

if pgrep -x qs >/dev/null && qs ipc call lock lock >/dev/null 2>&1; then
    # before-sleep: give the lock surface a moment to map before the machine suspends
    sleep 0.5
    exit 0
fi

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
