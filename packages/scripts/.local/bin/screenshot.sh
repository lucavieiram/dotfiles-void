#!/usr/bin/env bash
# screenshot.sh — grim/slurp-based screenshot utility
# Adapted from Hyprlust ScreenShot.sh; outputs to clipboard + saves a copy.
#
# Usage:
#     screenshot.sh area       # interactive area  → clipboard + ~/Pictures/Screenshots/
#     screenshot.sh window     # current focused window
#     screenshot.sh monitor    # focused output
#     screenshot.sh all        # all outputs
#     screenshot.sh frozen     # freeze screen then select
#     screenshot.sh color      # color picker (single pixel → clipboard as hex)

set -euo pipefail

OUT_DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$OUT_DIR"

ts=$(date +'%Y-%m-%d_%H-%M-%S')
file="$OUT_DIR/${ts}.png"

notify() { command -v notify-send >/dev/null && notify-send -i "$2" "Screenshot" "$1"; }
copy_and_save() {
    # stdin: PNG bytes
    tee "$file" | wl-copy -t image/png
    notify "Saved to $file (clipboard ready)" "$file"
}

current_monitor() {
    if command -v swaymsg >/dev/null; then
        swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name'
    fi
}

current_window_geometry() {
    # Returns geometry string "x,y wxh" of focused window
    swaymsg -t get_tree | jq -r '
        recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .rect |
        "\(.x),\(.y) \(.width)x\(.height)"'
}

case "${1:-area}" in
    area)
        grim -g "$(slurp -d -c '#fabd2f' -b '#1d202188')" - | copy_and_save
        ;;
    window)
        grim -g "$(current_window_geometry)" - | copy_and_save
        ;;
    monitor)
        mon=$(current_monitor)
        [ -n "$mon" ] || { echo "no focused monitor" >&2; exit 1; }
        grim -o "$mon" - | copy_and_save
        ;;
    all)
        grim - | copy_and_save
        ;;
    frozen)
        # freeze screen first (grim image into background); then slurp on top
        tmp=$(mktemp --suffix=.png)
        trap 'rm -f "$tmp"' EXIT
        grim "$tmp"
        imv -f "$tmp" &
        imv_pid=$!
        sleep 0.3
        region=$(slurp -d -c '#fabd2f' -b '#1d202188') || { kill $imv_pid 2>/dev/null; exit 1; }
        kill $imv_pid 2>/dev/null || true
        grim -g "$region" "$tmp" - | copy_and_save
        ;;
    color)
        # Single pixel color picker — output as #RRGGBB to clipboard (ImageMagick).
        pos=$(slurp -p -f '%x,%y')
        color=$(grim -g "${pos} 1x1" -t png - | \
            convert - -format '%[hex:p{0,0}]' info:)
        printf '#%s' "$color" | wl-copy
        notify "Color #${color} copied to clipboard" color-picker
        ;;
    -h|--help|help)
        sed -n '2,11p' "$0" | sed 's|^# \?||'
        ;;
    *)
        echo "unknown mode: $1" >&2; exit 64 ;;
esac
