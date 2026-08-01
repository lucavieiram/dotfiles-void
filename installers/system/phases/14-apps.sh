#!/usr/bin/env bash
# 14-apps.sh — Brave, KeePassXC, Nextcloud, Discord, Obsidian, yazi
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing GUI apps (xbps)"
xbps_install \
    keepassxc \
    nextcloud-client \
    yazi \
    fuse fuse3 \
    flatpak

info "Installing CUPS (printing)"
xbps_install cups
sudo ln -sf /etc/sv/cupsd /var/service/

info "Installing Brave browser"
if ! sudo xbps-install -y brave-browser >/dev/null 2>&1; then
    warn "brave-browser not in xbps; falling back to Flatpak"
    if command -v flatpak >/dev/null; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        sudo flatpak install -y --noninteractive flathub com.brave.Browser || \
            warn "Flatpak install failed; install Brave manually later."
    else
        warn "flatpak missing too; skipping Brave."
    fi
fi

info "Discord (Flatpak — not in xbps)"
if command -v flatpak >/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    sudo flatpak install -y --noninteractive flathub com.discordapp.Discord || \
        warn "Discord install failed; retry: flatpak install flathub com.discordapp.Discord"
else
    warn "flatpak not installed — skipping Discord"
fi

info "Installing Obsidian (latest AppImage)"
mkdir -p "$HOME/Applications"
OBSIDIAN_VER=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
    | grep '"tag_name"' \
    | sed 's/.*"v\([^"]*\)".*/\1/' || echo "")
if [ -n "$OBSIDIAN_VER" ]; then
    curl -fsSL \
        "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
        -o "$HOME/Applications/Obsidian.AppImage"
    chmod +x "$HOME/Applications/Obsidian.AppImage"
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/obsidian.desktop" <<EOF
[Desktop Entry]
Name=Obsidian
Exec=${HOME}/Applications/Obsidian.AppImage --ozone-platform-hint=auto %u
Icon=obsidian
Type=Application
Categories=Office;Productivity;
StartupWMClass=obsidian
EOF
    success "Obsidian ${OBSIDIAN_VER} installed"
else
    warn "Could not detect latest Obsidian version"
fi

success "Apps installed"
