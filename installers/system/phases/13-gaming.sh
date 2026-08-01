#!/usr/bin/env bash
# 13-gaming.sh — Steam (Flatpak, preferred over native) + 32-bit libs + gamemode.
# Native Steam package install also kept for fallback / users who prefer it.
# Skipped if NVIDIA module not loaded. Override: FORCE_GAMING=1.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

ASSETS_DIR="${REPO_DIR}/installers/system/assets"

if [ ! -d /sys/module/nvidia ] && [ "${FORCE_GAMING:-0}" != "1" ]; then
    warn "No NVIDIA module loaded — skipping gaming stack (override: FORCE_GAMING=1)"
    exit 0
fi

info "Installing 32-bit base libraries (Steam + Proton)"
xbps_install \
    glibc-32bit libgcc-32bit libstdc++-32bit \
    mesa-32bit mesa-dri-32bit \
    libglvnd-32bit \
    libX11-32bit libxcb-32bit \
    wayland-32bit

info "Installing performance tools (gamemode + gamescope)"
xbps_install gamemode gamescope

info "Writing /etc/gamemode.ini (CPU governor + GPU PowerMizer + pinning)"
sudo install -Dm644 "${ASSETS_DIR}/gamemode.ini" /etc/gamemode.ini

# Raise vm.max_map_count to the SteamOS value. Many games memory-map tens of
# thousands of asset files; the old Linux default (65530) is exhausted and the
# game crashes on load. PoE2 logs "[STORAGE] Failed to create file mapping
# (error: 4)"; Space Marine 2, Star Citizen, Hogwarts Legacy etc. hit the same.
info "Raising vm.max_map_count (games crash on the 65530 default)"
echo 'vm.max_map_count = 2147483642' | sudo tee /etc/sysctl.d/99-gaming.conf >/dev/null
sudo sysctl -w vm.max_map_count=2147483642 >/dev/null

# Raise the open-file-descriptor limit. Proton's esync opens one eventfd per
# Win32 sync object and PoE2 memory-maps thousands of asset files; the old Void
# default (nofile 4096) is exhausted and the game crashes on load with
# Win32 ERROR_TOO_MANY_OPEN_FILES (PoE2: "[STORAGE] Failed to create file
# mapping (error: 4)"). SteamOS uses 1048576. pam_limits.so is already in the
# greetd login chain (via system-auth), so this applies at next login.
info "Raising open-file limit (nofile) for Proton/esync"
sudo tee /etc/security/limits.d/99-gaming.conf >/dev/null <<'EOF'
# Managed by dotfiles-void (13-gaming.sh). High nofile for Proton esync + games.
*    soft    nofile    1048576
*    hard    nofile    1048576
EOF

# ── RAM safety net: earlyoom + 16G disk swapfile ──
# 16GB RAM + zram-only swap hard-froze the whole PC when PoE2 exhausted
# memory: zram lives *in* RAM, so under pressure the kernel thrashes in a
# reclaim storm before anything dies. Two-part fix: a real disk swapfile as
# deep overflow (zram stays primary — prio 32767 vs -2), and earlyoom to
# SIGTERM the hog before the desktop locks up.
info "Installing earlyoom (kills the RAM hog before the desktop freezes)"
xbps_install earlyoom
sudo ln -sf /etc/sv/earlyoom /var/service/

if [ ! -f /swapfile ]; then
    info "Creating 16G /swapfile (root is ext4 — fallocate is safe)"
    sudo fallocate -l 16G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile >/dev/null
    sudo swapon /swapfile
else
    info "/swapfile already exists — skipping creation"
fi
if ! grep -q '^/swapfile' /etc/fstab; then
    echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

# ── Steam: prefer Flatpak (more reliable runtime, better Wayland) ──
# Flatpak Steam's runtime ships gamemoderun internally and bridges to the
# host gamemoded daemon via D-Bus — no separate extension package needed.
info "Installing Steam via Flatpak (recommended)"
flatpak install -y --noninteractive flathub com.valvesoftware.Steam \
    || warn "Flatpak Steam install failed (Flathub not configured?)"

# Kernel xpad module (Xbox controller) is built-in:
sudo modprobe xpad 2>/dev/null || true

success "Gaming stack ready."
info ""
info "Steam launch options — common prefix (paste into Properties → Launch Options):"
info "    gamemoderun __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only %command% -novid -nojoy -vulkan -console"
info ""
info "Then pick an FPS strategy for the external Acer KG241 (75Hz, FreeSync 48-75):"
info "    Smooth/tear-free (single-player, casual):  +fps_max 72   (vsync OFF in-game; stays in VRR range)"
info "    Uncapped/low-latency (competitive, CS2):   +fps_max 0    (vsync OFF in-game; tears above 75fps)"
info ""
info "What each piece does:"
info "    gamemoderun                      → CPU governor + GPU PowerMizer + non-game core eviction"
info "    __NV_PRIME_RENDER_OFFLOAD=1      → use NVIDIA dGPU (not Intel iGPU)"
info "    __VK_LAYER_NV_optimus=NVIDIA_only → Vulkan picks NVIDIA, ignores Intel"
info "    -vulkan                          → Source 2 Vulkan renderer (better than GL on Linux)"
info "    +fps_max 72  → just under 75Hz keeps every frame inside FreeSync = no tearing, no stutter"
info "    +fps_max 0   → uncapped; pair with allow_tearing (Sway) for immediate present + low latency"
info ""
info "Requires __GL_GSYNC_ALLOWED=1 (set in /etc/environment) + 'adaptive_sync on' on HDMI-A-2."
