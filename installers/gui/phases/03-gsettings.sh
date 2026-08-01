#!/usr/bin/env bash
# 03-gsettings.sh — apply gruvbox-friendly GTK/icon/cursor settings.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

if ! command -v gsettings >/dev/null; then
    warn "gsettings not installed; skipping. Install glib if needed."
    exit 0
fi

if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    warn "No DBUS session — gsettings won't propagate to running apps."
    warn "Re-run after logging into Sway."
fi

gsettings set org.gnome.desktop.interface gtk-theme            'Adwaita-dark'           2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme         'prefer-dark'            2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme           'Papirus-Dark'           2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme         'Bibata-Modern-Classic'  2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size          24                       2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name            'Noto Sans 10'           2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name  'JetBrainsMono Nerd Font 10' 2>/dev/null || true

success "gsettings applied"
