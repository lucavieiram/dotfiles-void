#!/usr/bin/env bash
# 03-gpu.sh — graphics drivers
# Detects hardware:
#   * NVIDIA present  → installs nvidia + Mesa + 32-bit + Vulkan + GRUB params
#                       (target: Acer Nitro V15 Optimus, RTX 3050 Ampere)
#   * AMD             → installs Mesa amdgpu (untested but harmless)
#   * Intel only      → installs Mesa Intel
#
# Override detection with FORCE_GPU=nvidia|amd|intel
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/grub.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

# ── Detect ────────────────────────────────────────────────────────
detect_gpu() {
    if [ -n "${FORCE_GPU:-}" ]; then
        echo "$FORCE_GPU"
        return
    fi
    local pci
    pci=$(lspci -nn | grep -iE 'vga|3d controller|display' || true)
    if echo "$pci" | grep -qi nvidia; then
        echo "nvidia"
    elif echo "$pci" | grep -qi 'advanced micro devices'; then
        echo "amd"
    else
        echo "intel"
    fi
}

GPU="$(detect_gpu)"
info "Detected GPU profile: $GPU"

# ── Mesa baseline (always installed) ──────────────────────────────
info "Installing Mesa userspace"
xbps_install \
    mesa-dri mesa-vaapi libva-utils \
    vulkan-loader libglvnd

# ── Profile-specific ──────────────────────────────────────────────
case "$GPU" in
    nvidia)
        info "Installing Intel iGPU + NVIDIA proprietary driver (Optimus)"
        xbps_install mesa-vulkan-intel intel-video-accel
        xbps_install nvidia nvidia-libs nvidia-libs-32bit \
                     vulkan-loader-32bit libglvnd-32bit

        info "Rebuilding NVIDIA kernel module via DKMS"
        sudo xbps-reconfigure -f nvidia || warn "nvidia reconfigure failed (driver may not be installed)"

        info "Adding NVIDIA kernel parameters to GRUB cmdline"
        grub_add_cmdline "nvidia-drm.modeset=1"
        grub_add_cmdline "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        grub_add_cmdline "nvidia_drm.fbdev=1"
        grub_regenerate

        # NVIDIA modules + device nodes — defense-in-depth one-shot at boot.
        # nvidia-drm.modeset=1 (above) normally loads nvidia/nvidia_modeset/
        # nvidia_drm early, but this script modprobes ALL four explicitly
        # and creates the /dev/nvidia-uvm{,-tools} nodes that aren't
        # auto-created (nvidia-modprobe -u is broken in driver 595.x).
        # Vulkan ICD init inside sandboxes (Flatpak Steam, Proton) requires
        # /dev/nvidia-uvm to exist.
        info "Installing runit core-service for NVIDIA modules + uvm device nodes"
        sudo tee /etc/runit/core-services/99-nvidia-uvm.sh >/dev/null <<'BOOT'
#!/bin/sh
# Ensure ALL NVIDIA kernel modules + device nodes are ready before
# any graphical session starts.
for mod in nvidia nvidia_modeset nvidia_drm nvidia_uvm; do
    modprobe "$mod" 2>/dev/null
done

# nvidia0 + nvidiactl + nvidia-modeset get udev rules. nvidia-uvm
# does not — mknod it from the dynamic major.
MAJ=$(awk '/^[0-9]+ nvidia-uvm$/{print $1}' /proc/devices)
[ -n "$MAJ" ] || exit 0
[ -e /dev/nvidia-uvm ]       || mknod -m 666 /dev/nvidia-uvm       c "$MAJ" 0
[ -e /dev/nvidia-uvm-tools ] || mknod -m 666 /dev/nvidia-uvm-tools c "$MAJ" 1
exit 0
BOOT
        sudo chmod +x /etc/runit/core-services/99-nvidia-uvm.sh
        # Clean up earlier (non-Void) attempts that didn't run
        sudo rm -f /etc/udev/rules.d/99-nvidia-uvm.rules
        sudo rm -f /etc/modules-load.d/nvidia-uvm.conf
        ;;
    amd)
        info "Installing AMD support (Mesa amdgpu)"
        xbps_install mesa-vulkan-radeon mesa-vaapi
        ;;
    intel)
        info "Installing Intel iGPU support"
        xbps_install mesa-vulkan-intel intel-video-accel
        ;;
esac

# ── Write Sway GPU env include ────────────────────────────────────
# packages/sway/.config/sway/config.d/00-env.conf does:
#     include /etc/sway/gpu-env.conf
# We write that file here based on detected hardware.
# sway's `exec_always export …` doesn't actually set env in sway/children
# (the export runs in a subshell that exits). Real GPU env lives in
# ~/.zprofile and is inherited via tuigreet's `zsh -l -c "exec sway …"`.
# We still write /etc/sway/gpu-env.conf as a placeholder so the `include`
# in packages/sway/.config/sway/config.d/00-env.conf doesn't fail.
info "Writing /etc/sway/gpu-env.conf (placeholder — real env lives in ~/.zprofile)"
sudo mkdir -p /etc/sway
sudo tee /etc/sway/gpu-env.conf >/dev/null <<EOF
# GPU profile: $GPU (detected by 03-gpu.sh)
# Real env exports live in ~/.zprofile, sourced via greetd's zsh -l wrapper.
EOF

info "Visible GPUs:"
lspci -k -d ::03xx 2>/dev/null | sed 's/^/    /' || true

success "GPU stack installed (profile: $GPU)."
if [ "$GPU" = "nvidia" ]; then
    warn "Reboot required for NVIDIA module + GRUB cmdline params to load."
fi
info  "After reboot, verify with:"
info  "    glxinfo | grep 'OpenGL renderer'           # Intel"
info  "    prime-run glxinfo | grep 'OpenGL renderer' # NVIDIA"
info  "    nvidia-smi"
