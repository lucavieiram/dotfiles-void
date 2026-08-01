#!/usr/bin/env bash
# 05-wallpaper.sh — seed ~/Pictures/Wallpapers/ with a solid gruvbox default
# and create the current.png symlink that Sway autostart consumes.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

WP_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WP_DIR"

# If user already has images here (other than current.png), skip seeding.
existing=$(find "$WP_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    ! -name 'current.*' | head -1)

if [ -z "$existing" ]; then
    info "No wallpapers found — generating solid gruvbox-dark background"
    target="$WP_DIR/default.png"
    convert -size 1920x1080 'xc:#282828' "$target"
    existing="$target"
fi

# Point current.png at the first available wallpaper
if [ -n "$existing" ]; then
    ln -sfn "$existing" "$WP_DIR/current.png"
    success "Default wallpaper: $(basename "$existing")"
else
    warn "No wallpaper in $WP_DIR — Sway will boot with no background"
    warn "Add wallpapers to $WP_DIR then press Super+Shift+W in Sway"
fi

# If swaybg is running (we're already in Sway), refresh it
if pgrep -x swaybg >/dev/null && [ -L "$WP_DIR/current.png" ]; then
    pkill -x swaybg 2>/dev/null || true
    swaybg -i "$WP_DIR/current.png" -m fill &
    disown
fi
