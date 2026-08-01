#!/usr/bin/env bash
# 11-security.sh — AppArmor, nftables, sysctl hardening
# See docs/hardening-and-gaming.md for rationale.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/grub.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

ASSETS_DIR="${REPO_DIR}/installers/system/assets"

# ── AppArmor ──────────────────────────────────────────────────────
info "Installing AppArmor"
xbps_install apparmor

info "Setting AppArmor mode to complain (Void default, per security/apparmor.md)"
# enforce mode without custom profiles for everything you use provides
# little protection AND breaks apps silently (Steam runtime, etc.).
# complain logs would-be denials without blocking — useful for visibility
# and for later writing per-app profiles if needed. Switch back to enforce
# once you've authored a profile for whatever you specifically want sandboxed.
sudo sed -i 's/^APPARMOR=.*/APPARMOR=complain/' /etc/default/apparmor

# Kernel cmdline for AppArmor — uses the shared grub helper to avoid clobbering
# params set by other phases (03-gpu.sh adds nvidia-drm.modeset=1, etc.)
grub_add_cmdline "apparmor=1"
grub_add_cmdline "security=apparmor"
grub_regenerate

# ── nftables ──────────────────────────────────────────────────────
info "Installing nftables + runit integration"
xbps_install nftables runit-nftables

info "Installing nftables ruleset"
if [ -f "${ASSETS_DIR}/nftables.conf" ]; then
    sudo cp "${ASSETS_DIR}/nftables.conf" /etc/nftables.conf
else
    sudo tee /etc/nftables.conf >/dev/null <<'EOF'
#!/usr/sbin/nft -f
# Intentionally NO `flush ruleset` — Docker and libvirt manage their own
# tables (ip/ip6 filter, ip/ip6 nat) and flushing would wipe their chains,
# breaking container/VM networking until each daemon is restarted.
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iif lo accept
        icmp type echo-request limit rate 5/second accept
        icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert, echo-request } accept
        tcp dport 22 ct state new limit rate 10/minute accept
        counter drop
    }
    # Forward policy is accept so Docker bridges (docker0, br-*) and libvirt
    # (virbr0) can route container/VM traffic. Docker installs its own
    # FORWARD rules in `table ip filter` for per-bridge isolation.
    chain forward { type filter hook forward priority 0; policy accept; }
    chain output  { type filter hook output  priority 0; policy accept; }
}
EOF
fi
sudo chmod 644 /etc/nftables.conf
sudo ln -sf /etc/sv/nftables /var/service/

# ── sysctl hardening ──────────────────────────────────────────────
info "Applying sysctl hardening"
sudo mkdir -p /etc/sysctl.d
sudo tee /etc/sysctl.d/99-hardening.conf >/dev/null <<'EOF'
# Network
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1

# Kernel
kernel.kptr_restrict = 2
# dmesg readable by non-root: needed to self-diagnose GPU faults (NVRM/Xid)
# and OOM kills after a game/Steam crash. Void has no journald, so an
# unreadable ring buffer means crash evidence is lost on the power-cycle.
kernel.dmesg_restrict = 0
# Explicitly relaxed (Void/some kernels default these to 1, which breaks
# Steam Linux Runtime, Proton, anti-cheats, debuggers). The fs.* and
# kernel.kptr_restrict above already cover practical attack surface.
kernel.unprivileged_bpf_disabled = 0
kernel.yama.ptrace_scope = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0

# Process / fork capacity — kernel default on Void is 32768, dangerously low
# for any fork-heavy workload (Steam + games can saturate it and freeze the
# system, including the desktop session). Modern default is 4M.
kernel.pid_max = 4194304

# Memory (good defaults for SSD + 16GB)
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
sudo sysctl --system >/dev/null

# ── zram swap (compressed RAM swap, no SSD I/O) ───────────────────
# Without swap, any momentary RAM spike (Steam + game launch + browser)
# hits the OOM killer and freezes the desktop. zram gives breathing room
# via compressed RAM (lz4 default, ~3× ratio) — fast, zero SSD wear.
# Placed in /etc/runit/core-services/ so it runs at stage-1 boot BEFORE
# greetd; otherwise zramen's logs scroll over the tuigreet login UI.
info "Installing zramen + early-boot one-shot"
xbps_install zramen
sudo tee /etc/runit/core-services/04-zram.sh >/dev/null <<'EOF'
#!/bin/sh
# Set up zram swap early so greetd's tuigreet UI isn't scrolled by boot logs.
zramen make 2>/dev/null
EOF
sudo chmod +x /etc/runit/core-services/04-zram.sh
# Do NOT enable /var/service/zramen — would duplicate the activation.
sudo rm -f /var/service/zramen

# ── TRIM for SSD ──────────────────────────────────────────────────
info "Enabling weekly TRIM via cron"
sudo tee /etc/cron.weekly/fstrim >/dev/null <<'EOF'
#!/bin/sh
fstrim --all --verbose | logger -t fstrim
EOF
sudo chmod +x /etc/cron.weekly/fstrim

success "Security hardening applied."
warn  "AppArmor activation requires a reboot."
