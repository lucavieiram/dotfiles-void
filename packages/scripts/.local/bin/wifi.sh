#!/usr/bin/env bash
# wifi.sh — small nmcli wrapper for everyday wifi tasks.
# All real work is done by nmcli — this is just shorter to type and remember.
#
# Examples:
#   wifi list                 # scan and show nearby networks
#   wifi connect MyHomeWifi   # connect (prompts for password if new)
#   wifi connect Eduroam user pass
#   wifi forget MyHomeWifi    # delete saved credentials
#   wifi current              # what am I on?
#   wifi on / wifi off        # radio toggle

set -euo pipefail

require_nm() {
    command -v nmcli >/dev/null || { echo "nmcli not installed"; exit 1; }
    pgrep -x NetworkManager >/dev/null || { echo "NetworkManager not running — try: sudo sv up NetworkManager"; exit 1; }
}

case "${1:-}" in
    list|ls|scan)
        require_nm
        nmcli device wifi rescan 2>/dev/null || true
        nmcli -f IN-USE,BARS,SIGNAL,SECURITY,SSID device wifi list
        ;;
    connect|c)
        require_nm
        ssid="${2:?usage: wifi connect <SSID> [password]}"
        if [ -n "${3:-}" ]; then
            nmcli device wifi connect "$ssid" password "$3"
        else
            # If already known, just bring it up; otherwise nmcli prompts.
            if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
                nmcli connection up "$ssid"
            else
                read -rsp "Password for $ssid (empty if open): " pw; echo
                if [ -n "$pw" ]; then
                    nmcli device wifi connect "$ssid" password "$pw"
                else
                    nmcli device wifi connect "$ssid"
                fi
            fi
        fi
        ;;
    forget|rm)
        require_nm
        ssid="${2:?usage: wifi forget <SSID>}"
        nmcli connection delete "$ssid"
        ;;
    current|status)
        require_nm
        nmcli -t -f NAME,DEVICE,TYPE,STATE connection show --active
        ;;
    on)   require_nm; nmcli radio wifi on ;;
    off)  require_nm; nmcli radio wifi off ;;
    portal)
        # Force-open a captive-portal login page. Normally the browser /
        # nm-applet auto-detect fires on its own; use this when it doesn't.
        # The URL is HTTP (not HTTPS) so the portal can intercept it.
        ( xdg-open 'http://detectportal.firefox.com/canonical.html' >/dev/null 2>&1 & )
        ;;
    diagnose|debug)
        # Captive-portal / dead-link debug. Runs offline, prints to terminal,
        # saves a copy to ~/wifi-debug-<ts>.log so it can be reviewed later.
        require_nm
        log="$HOME/wifi-debug-$(date +%Y%m%d-%H%M%S).log"
        exec > >(tee "$log") 2>&1
        echo "=== wifi diagnose @ $(date -Is) ==="
        echo
        echo "--- active connection ---"
        nmcli -t -f NAME,DEVICE,TYPE,STATE connection show --active
        echo
        echo "--- NM connectivity check ---"
        nmcli networking connectivity check
        echo
        echo "--- routes ---"
        ip route
        gw=$(ip route | awk '/default/{print $3; exit}')
        echo
        echo "--- DNS servers ---"
        grep -E '^(nameserver|search)' /etc/resolv.conf 2>/dev/null || echo "(no /etc/resolv.conf)"
        echo
        if [ -n "$gw" ]; then
            echo "--- ping gateway ($gw) ---"
            ping -c2 -W2 "$gw" || true
        else
            echo "!! no default gateway — DHCP didn't complete"
        fi
        echo
        echo "--- DNS resolve neverssl.com ---"
        getent hosts neverssl.com || echo "!! DNS resolution failed"
        echo
        echo "--- HTTP probe: neverssl.com ---"
        curl -sS -v --max-time 5 -o /dev/null http://neverssl.com 2>&1 | grep -E '^(\*|<|>)' | head -30 || true
        echo
        echo "--- HTTP probe: detectportal.firefox.com ---"
        curl -sS --max-time 5 -o - http://detectportal.firefox.com/canonical.html 2>&1 | head -5 || true
        echo
        echo "=== saved to: $log ==="
        ;;
    *)
        cat <<EOF
usage: wifi {list|connect|forget|current|on|off|portal|diagnose}

  list                          scan and show nearby networks
  connect <SSID> [password]     connect (prompts if new + no password given)
  forget <SSID>                 delete saved credentials
  current                       show active connection(s)
  on | off                      toggle wifi radio
  portal                        open browser to a captive-portal probe URL
  diagnose                      run portal/connectivity checks, save log
EOF
        exit 2
        ;;
esac
