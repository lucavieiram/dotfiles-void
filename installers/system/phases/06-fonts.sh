#!/usr/bin/env bash
# 06-fonts.sh — fonts, cursors, icons
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing fonts (names vary across Void versions; misses are skipped)"
xbps_install \
    nerd-fonts-symbols-ttf \
    font-awesome \
    font-awesome6 \
    noto-fonts-ttf \
    noto-fonts-emoji \
    noto-fonts-cjk \
    liberation-fonts-ttf \
    dejavu-fonts-ttf

# Nerd Fonts: deliberately NOT the Void 'nerd-fonts' meta — it ships every
# patched family in TTF+OTF (~7.9GB installed). The configs use exactly two
# families (JetBrainsMono everywhere, Ubuntu in Waybar), so fetch just those
# from upstream releases into the user font dir (~100MB total).
NF_VERSION="3.4.0"
NF_DIR="${HOME}/.local/share/fonts"
nf_install_family() {
    local family="$1" dest="${NF_DIR}/${1}NF"
    if ls "${dest}"/*.ttf >/dev/null 2>&1; then
        info "  ${family} Nerd Font already present — skipping"
        return 0
    fi
    info "  Fetching ${family} Nerd Font v${NF_VERSION}"
    mkdir -p "${dest}"
    if ! curl -sfL "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}/${family}.tar.xz" \
            | tar xJ -C "${dest}" --wildcards '*.ttf'; then
        warn "  download failed: ${family} Nerd Font — install manually into ${dest}"
        rmdir "${dest}" 2>/dev/null || true
    fi
}

info "Installing Nerd Fonts (JetBrainsMono + Ubuntu families only)"
nf_install_family JetBrainsMono
nf_install_family Ubuntu

info "Installing cursor and icon themes"
xbps_install papirus-icon-theme
# bibata-cursor not in Void repos — install manually from
# https://github.com/ful1e5/Bibata_Cursor/releases if desired.

info "Installing GTK theme support"
xbps_install \
    gnome-themes-extra \
    qt5ct qt6ct kvantum
# adw-gtk3 not in Void repos. Install manually if desired:
#   git clone https://github.com/lassekongo83/adw-gtk3.git && cd adw-gtk3 && meson setup build && meson install -C build --destdir ~/.local
# or via Flatpak: flatpak install org.gtk.Gtk3theme.adw-gtk3

info "Refreshing font cache"
fc-cache -f >/dev/null
sudo fc-cache -fv >/dev/null

success "Fonts and themes installed"
