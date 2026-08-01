# Networking

How wifi, DNS, captive portals, and Mullvad VPN are wired together on this system.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│ NetworkManager (default dns mode, writes resolv.conf from DHCP)      │
│   ├── eth0      ← DHCP                                               │
│   ├── wlan0     ← wifi profiles (wpa_supplicant backend)             │
│   └── mlvd-*    ← Mullvad WireGuard (imported via nmcli)             │
│                                                                       │
│   Detects captive portals via `nmcheck.gnome.org` probe.             │
│   nm-applet (in Sway autostart) shows portal login notifications.    │
│   Firefox/Chromium also detect via their own probe and show a        │
│   "Log in to network" bar.                                           │
└──────────────────────────────────────────────────────────────────────┘
                                  │
                  /etc/resolv.conf (written by NM from DHCP)
```

## Why this design

Earlier this setup used `dnscrypt-proxy` for DoH-encrypted DNS to
Cloudflare/Quad9/Mullvad. It was removed because:

- It broke captive portals every single time (university, hotels, cafés)
  since the portal can't hijack DNS that goes over TLS/443.
- The privacy gain was modest: SNI still leaks visited hostnames in
  plaintext on the wire, so DNS encryption alone doesn't hide much.
- Real privacy on hostile networks is handled by **Mullvad VPN on
  demand** — which encrypts everything, not just DNS.

For this laptop the trade — usability > philosophical purity — was the
right call. Servers get a stricter policy; this repo only covers the laptop.

## Files

| Path | Purpose |
|---|---|
| `installers/system/phases/12-network.sh`      | Install + configure (idempotent) |
| `installers/system/assets/NetworkManager.conf`| NM main config (MAC randomization, captive portal probe) |
| `packages/scripts/.local/bin/wifi.sh`         | nmcli wrapper |
| `packages/scripts/.local/bin/mullvad.sh`      | Mullvad WG via NM |

## Everyday workflows

### Connect to wifi

```sh
wifi list
wifi connect "MyHomeWifi"          # prompts for password if new
wifi connect "Cafe Open Wifi"      # prompts; just press Enter for open networks
wifi current                       # what am I on?
wifi forget "Old Network"
```

Saved networks auto-reconnect via NM. No need to retype.

### Captive portal (faculdade, hotel, café)

Just connect and open the browser — nothing else to do. Firefox/Chromium
detect the portal and show a "Log in to network" prompt. `nm-applet` in
the Sway tray fires a notification as well.

If the browser doesn't auto-open the portal, try one of these HTTP-only
URLs (HTTPS pages can't be hijacked by the portal):

```
http://neverssl.com
http://captive.apple.com
http://nmcheck.gnome.org/check_network_status.txt
```

### Mullvad VPN

First time:

```sh
# 1. Get configs from https://mullvad.net/account/wireguard-config
#    Download e.g. mlvd-de-ber-wg-001.conf
mullvad import ~/Downloads/mlvd-de-ber-wg-001.conf
```

Daily use:

```sh
mullvad up mlvd-de-ber-wg-001
mullvad status                     # confirms via am.i.mullvad.net
mullvad down
mullvad list                       # imported profiles + active
```

Mullvad pushes its own DNS while the tunnel is up, so DNS goes through
the VPN — no extra config needed.

## Troubleshooting

### Captive portal page won't load

1. Check `nmcli general status` shows `connected (site only)` or
   `connectivity: limited` — that's the portal blocking you.
2. Open an **HTTP** URL (not HTTPS):
   `http://neverssl.com` or `http://captive.apple.com`.
3. If Firefox does DoH (DNS-over-HTTPS) and ignores the portal's DNS
   hijack: `about:config` → set `network.trr.mode` to `5` (off) until
   you've logged in.

### NetworkManager doesn't see my wifi

```sh
sv status NetworkManager
nmcli device                  # is wlan0 listed?
nmcli radio wifi              # is the radio on?
nmcli radio wifi on
sudo rfkill unblock wifi
```

### resolv.conf is empty after reconnect

Force a reapply: `nmcli device reapply <iface>`. If still empty, restart
NM: `sudo sv restart NetworkManager`.
