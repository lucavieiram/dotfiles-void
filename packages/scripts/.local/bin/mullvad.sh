#!/usr/bin/env bash
# mullvad.sh — manage Mullvad WireGuard connections via NetworkManager.
#
# Workflow:
#   1. Generate WG configs at https://mullvad.net/account/wireguard-config
#      Download the .conf files for the exit servers you want.
#   2. mullvad import ~/Downloads/mlvd-de-ber-wg-001.conf
#   3. mullvad up   mlvd-de-ber-wg-001
#   4. mullvad down
#
# Notes:
#   - We use NM's native WireGuard support — no wg-quick service needed.
#   - DNS: NM pushes Mullvad's DNS (10.64.0.1) while the tunnel is up, so
#     DNS goes through Mullvad and is private end-to-end. Off the VPN,
#     DNS reverts to whatever the DHCP server provides.
#   - Kill switch: enable by adding `connection.autoconnect-priority=999`
#     and a default-route firewall rule. Not done here by default.

set -euo pipefail

require_nm() {
    command -v nmcli >/dev/null || { echo "nmcli not installed"; exit 1; }
    pgrep -x NetworkManager >/dev/null || { echo "NetworkManager not running"; exit 1; }
}

case "${1:-}" in
    import)
        require_nm
        file="${2:?usage: mullvad import <path/to/mlvd-*.conf>}"
        [ -r "$file" ] || { echo "cannot read $file"; exit 1; }
        nmcli connection import type wireguard file "$file"
        name=$(basename "$file" .conf)
        echo "Imported as: $name"
        echo "Bring up with: mullvad up $name"
        ;;
    up)
        require_nm
        profile="${2:?usage: mullvad up <profile-name>}"
        nmcli connection up "$profile"
        echo "Verify exit IP: curl -s https://am.i.mullvad.net/connected"
        ;;
    down)
        require_nm
        # Bring down any active wireguard connection (NM doesn't have a
        # generic "all VPNs down" so we iterate).
        active=$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="wireguard"{print $1}')
        if [ -z "$active" ]; then
            echo "No active WireGuard connection."
            exit 0
        fi
        echo "$active" | while IFS= read -r c; do nmcli connection down "$c"; done
        ;;
    list|ls)
        require_nm
        echo "── Mullvad profiles (WireGuard, imported into NM) ──"
        nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="wireguard"{print "  " $1}'
        echo
        echo "── Currently active ──"
        nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="wireguard"{print "  " $1}' \
            | { grep -q . || echo "  (none)"; }
        ;;
    status)
        require_nm
        active=$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="wireguard"{print $1}')
        if [ -z "$active" ]; then
            echo "Mullvad: OFF"
            exit 0
        fi
        echo "Mullvad: ON ($active)"
        if command -v curl >/dev/null; then
            curl -s --max-time 5 https://am.i.mullvad.net/json | head -c 400; echo
        fi
        ;;
    *)
        cat <<EOF
usage: mullvad {import|up|down|list|status}

  import <file.conf>     register a Mullvad WireGuard config with NM
  up     <profile>       activate a profile
  down                   deactivate all active WireGuard connections
  list                   show imported profiles and active ones
  status                 check if VPN is on and what exit IP says

First time:
  1. Download configs from https://mullvad.net/account/wireguard-config
  2. mullvad import ~/Downloads/mlvd-de-ber-wg-001.conf
  3. mullvad up   mlvd-de-ber-wg-001
EOF
        exit 2
        ;;
esac
