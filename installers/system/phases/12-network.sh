#!/usr/bin/env bash
# 12-network.sh — NetworkManager installation & config.
#
# Architecture (simple):
#   NetworkManager ── manages connections, DHCP, captive-portal detection
#         │
#   /etc/resolv.conf ← written by NM from DHCP DNS each connect
#
# Privacy of DNS in hostile networks is handled by Mullvad VPN on demand
# (see packages/scripts/.local/bin/mullvad.sh), not by a local DoH proxy —
# the latter fights captive portals every time.
#
# This phase is IDEMPOTENT and SAFE to re-run.

set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

ASSETS_DIR="${REPO_DIR}/installers/system/assets"

# ── packages ──────────────────────────────────────────────────────
info "Installing NetworkManager"
xbps_install NetworkManager network-manager-applet

# ── NetworkManager config ─────────────────────────────────────────
info "Writing /etc/NetworkManager/NetworkManager.conf"
if [ ! -f "${ASSETS_DIR}/NetworkManager.conf" ]; then
    die "Missing asset: ${ASSETS_DIR}/NetworkManager.conf"
fi
sudo install -Dm644 "${ASSETS_DIR}/NetworkManager.conf" \
    /etc/NetworkManager/NetworkManager.conf

# ── enable service ────────────────────────────────────────────────
# NetworkManager will conflict with dhcpcd if both manage the same interface.
# On a fresh install (no dhcpcd-eth0 running) this is safe. On an existing
# system using dhcpcd, disable it first.
if [ -e /var/service/dhcpcd-eth0 ] || [ -e /var/service/dhcpcd ]; then
    warn "dhcpcd is currently enabled — NOT enabling NetworkManager yet."
    warn "To swap (run on a trusted network):"
    warn "    sudo rm /var/service/dhcpcd /var/service/dhcpcd-eth0 /var/service/wpa_supplicant"
    warn "    sudo ln -sf /etc/sv/NetworkManager /var/service/"
else
    info "Enabling NetworkManager service"
    sudo ln -sf /etc/sv/NetworkManager /var/service/
fi

success "NetworkManager installed and configured."
