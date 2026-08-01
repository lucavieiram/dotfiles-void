#!/usr/bin/env bash
# 17-finalize.sh — fc-cache, mandb refresh, summary
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

info "Refreshing font cache"
sudo fc-cache -fv >/dev/null
fc-cache -fv >/dev/null

info "Updating mandb"
sudo mandb --quiet 2>/dev/null || true

info "Verifying critical services are linked"
EXPECTED_SVCS=(dbus seatd nftables crond tlp unbound)
for svc in "${EXPECTED_SVCS[@]}"; do
    if [ -L "/var/service/${svc}" ]; then
        info "  ✓ ${svc}"
    else
        warn "  ✗ ${svc} — not linked"
    fi
done

section "system installation summary"

info "What's installed:"
info "  - Wayland: swayfx, Waybar, foot, fuzzel, dunst, gtklock, swayidle, autotiling"
info "  - Login: tuigreet (greetd)"
info "  - Audio: PipeWire + WirePlumber + ALSA + Bluetooth + PulseAudio compat"
info "  - GPU: NVIDIA + Intel iGPU (PRIME Render Offload — use 'prime-run' for games)"
info "  - Security: AppArmor (enforce), nftables, sysctl hardening, unbound DNS-over-TLS"
info "  - Power: TLP, elogind"
info "  - DevOps: docker, wireguard, gpg"
info "  - Gaming: Steam + Proton, gamescope, gamemode (no wine/lutris)"
info "  - Apps: KeePassXC, Nextcloud, Brave, Discord (Flatpak), Obsidian (AppImage)"
info "  - Shell: zsh, neovim, yazi, starship, CLI productivity tools"
info ""
info "Next steps:"
info "  1. sudo reboot                       (apply NVIDIA, AppArmor, GRUB cmdline)"
info "  2. Log in via greetd → Sway          (Gruvbox themed login)"
info "  3. cd ~/dotfiles-void && ./install.sh gui"
info "  4. swaymsg reload"
info ""
success "System installation complete."
