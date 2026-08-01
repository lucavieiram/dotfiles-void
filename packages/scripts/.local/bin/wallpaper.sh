#!/usr/bin/env bash
# wallpaper.sh — set wallpaper in ~/Pictures/Wallpapers/ via swaybg.
# Usage: wallpaper.sh {select|next|prev|random}

set -euo pipefail

WP_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
mkdir -p "$WP_DIR"

mapfile -t WALLS < <(find -L "$WP_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    ! -name 'current.*' | sort)

if [ "${#WALLS[@]}" -eq 0 ]; then
    notify-send -u critical "Wallpaper" "No images in $WP_DIR"
    exit 1
fi

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-cycle-index"
mkdir -p "$(dirname "$STATE_FILE")"

current_idx=0
[ -f "$STATE_FILE" ] && current_idx=$(cat "$STATE_FILE")

case "${1:-select}" in
    select)
        choice=$(
            for w in "${WALLS[@]}"; do
                basename "$w"
            done | fuzzel --dmenu --prompt 'Wallpaper: ' --lines 12 --width 50
        )
        [ -z "$choice" ] && exit 0
        target=""
        new_idx=0
        for i in "${!WALLS[@]}"; do
            if [ "$(basename "${WALLS[$i]}")" = "$choice" ]; then
                target="${WALLS[$i]}"
                new_idx=$i
                break
            fi
        done
        [ -n "$target" ] || exit 1
        ;;
    next)   new_idx=$(( (current_idx + 1) % ${#WALLS[@]} ));               target="${WALLS[$new_idx]}" ;;
    prev)   new_idx=$(( (current_idx - 1 + ${#WALLS[@]}) % ${#WALLS[@]} )); target="${WALLS[$new_idx]}" ;;
    random) new_idx=$(( RANDOM % ${#WALLS[@]} ));                          target="${WALLS[$new_idx]}" ;;
    *)      echo "usage: $0 {select|next|prev|random}" >&2; exit 64 ;;
esac

echo "$new_idx" > "$STATE_FILE"
ln -sf "$target" "$WP_DIR/current.png"

pkill -x swaybg 2>/dev/null || true
swaybg -i "$WP_DIR/current.png" -m fill &
disown

notify-send -t 1500 -i "$target" "Wallpaper" "$(basename "$target")"
