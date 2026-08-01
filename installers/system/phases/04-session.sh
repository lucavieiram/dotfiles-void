#!/usr/bin/env bash
# 04-session.sh — seat manager (seatd), elogind, dbus, polkit
# Required by Sway + Wayland apps for input devices, power events, privilege escalation
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing session management stack"
xbps_install \
    seatd elogind dbus polkit \
    lxqt-policykit \
    xdg-utils xdg-user-dirs \
    gnome-keyring
# gnome-keyring provides the org.freedesktop.secrets D-Bus service (a Secret
# Service) so the Nextcloud client and Chromium/Brave persist credentials
# across reboots instead of re-prompting / hanging on startup. Void's greetd
# PAM (/etc/pam.d/greetd, package-owned) already ships the pam_gnome_keyring
# auth + session(auto_start) hooks — installing this package activates them,
# auto-unlocking the "login" keyring with the login password. No PAM edits.

info "Installing turnstile (per-user services + reliable XDG_RUNTIME_DIR)"
xbps_install turnstile turnstile-runit

# Per Void docs (session-management.md):
#   "If using turnstile with elogind, disable rundir (XDG_RUNTIME_DIR)
#    management in /etc/turnstile/turnstiled.conf by setting manage_rundir
#    to no."
# We use elogind (above), so let elogind own XDG_RUNTIME_DIR.
info "Configuring turnstile to defer rundir to elogind"
if [ -f /etc/turnstile/turnstiled.conf ]; then
    if grep -q '^manage_rundir' /etc/turnstile/turnstiled.conf; then
        sudo sed -i 's/^manage_rundir.*/manage_rundir = no/' /etc/turnstile/turnstiled.conf
    else
        echo 'manage_rundir = no' | sudo tee -a /etc/turnstile/turnstiled.conf >/dev/null
    fi
fi

info "Enabling services"
sudo ln -sf /etc/sv/dbus /var/service/
sudo ln -sf /etc/sv/seatd /var/service/
# elogind is auto-activated by dbus on demand. Enabling it via runit causes
# duplicate-startup races ("elogind is already running as PID X") and breaks
# session creation (SDDM login hangs).
# sudo ln -sf /etc/sv/elogind /var/service/   # do NOT enable manually

# Turnstile creates a turnstiled service when installed
if [ -d /etc/sv/turnstiled ]; then
    info "Enabling turnstiled"
    sudo ln -sf /etc/sv/turnstiled /var/service/
fi

# acpid conflicts with elogind for lid/power events — disable if present
if [ -L /var/service/acpid ]; then
    info "Disabling acpid (conflicts with elogind for power events)"
    sudo rm -f /var/service/acpid
fi

info "Adding user $(whoami) to _seatd group"
sudo usermod -aG _seatd "$(whoami)"

# Set up turnstile user service directory (will be populated by gui install)
mkdir -p "$HOME/.config/service"

# ── /etc/environment ──────────────────────────────────────────────
# Set graphical-session env vars at PAM login time so they're available
# to every program — sway, greetd, ssh, cron — without needing a shell
# wrapper around the session command. Standard Linux mechanism.
info "Writing /etc/environment (PAM env for the graphical session)"
sudo tee /etc/environment >/dev/null <<'EOF'
# Managed by dotfiles-void (installers/system/phases/04-session.sh).
# PAM (pam_env.so) sources this at login so every program inherits these.

XDG_CURRENT_DESKTOP=sway
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=sway

# Wayland-native rendering
GDK_BACKEND=wayland
QT_QPA_PLATFORM="wayland;xcb"
QT_AUTO_SCREEN_SCALE_FACTOR=1
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
MOZ_ENABLE_WAYLAND=1
NIXOS_OZONE_WL=1
_JAVA_AWT_WM_NONREPARENTING=1

# NVIDIA workarounds (harmless on non-NVIDIA hardware)
WLR_NO_HARDWARE_CURSORS=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
# Allow G-Sync/VRR. The external HDMI monitor (Acer KG241, on the dGPU) exposes
# FreeSync over HDMI in the 48-75 Hz range; this lets adaptive_sync engage.
__GL_GSYNC_ALLOWED=1
# PRIME render offload — all OpenGL/Vulkan apps render on NVIDIA dGPU.
# Justified on this hardware: HDMI-A-2 is wired to dGPU, so NVIDIA is awake
# whenever the external monitor is plugged. Rendering on NVIDIA eliminates
# the cross-PCIe Intel→NVIDIA bridge that would otherwise happen per frame.
__NV_PRIME_RENDER_OFFLOAD=1
# Video decode stays on Intel iGPU (intel-media-driver). nvidia-vaapi-driver
# would be needed to switch to NVIDIA decode.
LIBVA_DRIVER_NAME=iHD
GBM_BACKEND=nvidia-drm

# Default apps
EDITOR=nvim
VISUAL=nvim
BROWSER=firefox
TERMINAL=foot
EOF

success "Session stack ready. (Group membership applies after re-login.)"
info "Polkit agent will be autostarted from Sway config (50-autostart.conf)."
