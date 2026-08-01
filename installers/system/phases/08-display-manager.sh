#!/usr/bin/env bash
# 08-display-manager.sh — greetd + tuigreet (TUI).
#
# Chain:  greetd → tuigreet → user logs in → Sway starts
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

# Disable previous login managers
for prev in sddm ly; do
    if [ -L "/var/service/${prev}" ]; then
        info "Disabling previous login manager: ${prev}"
        sudo rm -f "/var/service/${prev}"
    fi
done

info "Installing greetd + tuigreet"
xbps_install greetd tuigreet

# Register Sway as a wayland session greetd can launch.
# Session-wide env vars (XDG_CURRENT_DESKTOP, GDK_BACKEND, NIXOS_OZONE_WL,
# NVIDIA workarounds, …) live in /etc/environment and are set by PAM at
# login, so sway can be started directly without any shell wrapper.
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/sway.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Sway
Comment=Tiling Wayland compositor
Exec=sway --unsupported-gpu
Type=Application
EOF

info "Writing /etc/greetd/config.toml"
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
# Sway wrapped in dbus-run-session so the user session bus lives at the
# canonical $XDG_RUNTIME_DIR/bus path. Without this, sway auto-spawns dbus
# at /tmp/dbus-XXXXX and Flatpak apps (which hard-code /run/user/$UID/bus)
# fail to start. See docs/troubleshooting.md.
command = "tuigreet --time --remember --remember-session --asterisks --cmd 'dbus-run-session sway --unsupported-gpu'"
user = "_greetd"
EOF

info "Ensuring _greetd user exists (Void greetd package doesn't auto-create it)"
if ! id _greetd >/dev/null 2>&1; then
    sudo useradd -r -M -s /sbin/nologin -d /var/lib/greetd _greetd
    sudo usermod -aG video,input,_seatd _greetd 2>/dev/null || true
    sudo mkdir -p /var/lib/greetd
    sudo chown _greetd:_greetd /var/lib/greetd
fi

info "Freeing TTY1 (agetty would race with greetd)"
sudo rm -f /var/service/agetty-tty1

info "Enabling greetd service"
sudo ln -sf /etc/sv/greetd /var/service/

success "Display manager configured (tuigreet TUI)."
warn "Reboot to see the login. If broken, recover via TTY: sudo rm /var/service/greetd"
