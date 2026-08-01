#!/usr/bin/env bash
# 05-audio.sh — PipeWire + WirePlumber + Bluetooth (per official void-docs)
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing PipeWire + Bluetooth stack"
xbps_install \
    pipewire wireplumber \
    alsa-pipewire libspa-bluetooth \
    pulseaudio-utils \
    pavucontrol playerctl pamixer \
    bluez blueman

info "Wiring system-wide PipeWire configuration"
sudo mkdir -p /etc/pipewire/pipewire.conf.d /etc/alsa/conf.d

sudo ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf \
    /etc/pipewire/pipewire.conf.d/10-wireplumber.conf

sudo ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf \
    /etc/pipewire/pipewire.conf.d/20-pipewire-pulse.conf

sudo ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
sudo ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/

info "Enabling bluetoothd service"
sudo ln -sf /etc/sv/bluetoothd /var/service/

# bluez doesn't auto-create its state dir on all Void installs; without
# it bluetoothd registers no controller and `bluetoothctl show` returns
# "No default controller available".
info "Ensuring /var/lib/bluetooth exists"
sudo mkdir -p /var/lib/bluetooth
sudo chmod 700 /var/lib/bluetooth

# AutoEnable defaults to commented (= false) in fresh installs, which
# leaves the controller soft-off after boot.
info "Enabling AutoEnable in /etc/bluetooth/main.conf"
sudo sed -i 's/^#AutoEnable=true/AutoEnable=true/' /etc/bluetooth/main.conf

# Acer WMI firmware soft-blocks bluetooth at every cold boot. Unblock
# now; the sway autostart unblocks on every session (handles reboots)
# via a NOPASSWD sudoers rule scoped to rfkill unblock.
info "Unblocking bluetooth (rfkill)"
sudo rfkill unblock bluetooth

info "Allowing wheel to run 'rfkill unblock' passwordlessly"
sudo tee /etc/sudoers.d/10-rfkill-unblock >/dev/null <<'EOF'
%wheel ALL=(root) NOPASSWD: /usr/sbin/rfkill unblock *
EOF
sudo chmod 0440 /etc/sudoers.d/10-rfkill-unblock

# PipeWire is launched from Sway autostart (see packages/sway/.config/sway/config.d/50-autostart.conf)
success "PipeWire + Bluetooth configured. PipeWire will start with Sway session."
