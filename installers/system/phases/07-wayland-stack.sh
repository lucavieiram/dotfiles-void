#!/usr/bin/env bash
# 07-wayland-stack.sh — swayfx, Waybar, foot, fuzzel, dunst, etc.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing Wayland compositor and apps"
# swayfx (Sway fork w/ blur + corner_radius). No fallback — if missing,
# installation fails. Build via xbps-src or wait for repo if unavailable.
xbps_install swayfx

xbps_install \
    swaybg swayidle gtklock \
    Waybar foot fuzzel dunst \
    autotiling wlogout \
    grim slurp wl-clipboard cliphist \
    brightnessctl \
    network-manager-applet \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    imv mpv zathura zathura-pdf-poppler

success "Wayland stack installed (swayfx + fuzzel + dunst)"
