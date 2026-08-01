#!/usr/bin/env bash
# 10-devops.sh — essential devops tooling: docker, vpn, gpg, dns
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

ASSETS_DIR="${REPO_DIR}/installers/system/assets"

info "Installing containers"
xbps_install docker docker-compose

# Docker daemon config. default-address-pools moves auto-allocated bridges
# out of 172.18.0.0/16 — that range collided with the PUC Goiás DNS server
# (172.18.1.255) and broke captive-portal login whenever a custom bridge
# (e.g. k3d clusters) was up.
info "Writing /etc/docker/daemon.json"
if [ ! -f "${ASSETS_DIR}/docker-daemon.json" ]; then
    die "Missing asset: ${ASSETS_DIR}/docker-daemon.json"
fi
sudo install -Dm644 "${ASSETS_DIR}/docker-daemon.json" /etc/docker/daemon.json

info "Installing VPN + DNS tooling"
# wireguard-tools: Mullvad / personal WG configs (used by NetworkManager too)
# bind-utils: dig/host for debugging
xbps_install wireguard-tools bind-utils

info "Installing GPG tooling"
xbps_install gnupg2 pinentry pinentry-curses

info "Enabling docker service"
sudo ln -sf /etc/sv/docker /var/service/

info "Adding $(whoami) to docker group"
sudo usermod -aG docker "$(whoami)"

success "DevOps stack installed"
warn  "Re-login required for docker group membership to apply."
