#!/usr/bin/env bash
# 15-power.sh — power & thermal management
#   - TLP for battery life
#   - Acer Nitro (ANV15-51) thermal/profile stack: linuwu-sense (DKMS) +
#     acer-power runit daemon + waybar-clickable profile switcher
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

ASSETS_DIR="${REPO_DIR}/installers/system/assets"

info "Installing TLP (laptop power manager)"
xbps_install tlp tlp-rdw

info "Default TLP configuration (sensible for Acer Nitro + NVIDIA Optimus)"
sudo tee /etc/tlp.d/99-local.conf >/dev/null <<'EOF'
# CPU
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# NVIDIA Optimus — let runtime PM handle the dGPU
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# WiFi power save
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Battery thresholds (keep 60-80% for longevity if your battery supports it)
# Uncomment after verifying with: tlp-stat -b
# START_CHARGE_THRESH_BAT0=60
# STOP_CHARGE_THRESH_BAT0=80

# USB autosuspend
USB_AUTOSUSPEND=1

# Disk
DISK_IOSCHED="mq-deadline mq-deadline"
EOF

info "Enabling tlp service"
sudo ln -sf /etc/sv/tlp /var/service/

success "TLP installed. Run 'sudo tlp-stat' after reboot to verify."

# ──────────────────────────────────────────────────────────────────────────
# Acer Nitro V (ANV15-51) thermal + power-profile stack
#
# NitroSense-equivalent on Linux: the linuwu-sense kernel module exposes
# /sys/firmware/acpi/platform_profile + per-fan control, driven by a small
# runit daemon (acer-power) that reacts to AC/battery/temperature, plus a
# waybar-clickable CLI switcher (acer-profile-switcher).
#
# linuwu-sense is built via DKMS so it auto-rebuilds on every kernel update.
# It is NOT a packaged module: a one-off manual build silently breaks on the
# next kernel bump — which is exactly how this whole stack died once before.
# ──────────────────────────────────────────────────────────────────────────
section "Acer Nitro thermal/profile stack"

LINUWU_REPO="https://github.com/0x7375646F/Linuwu-Sense.git"
LINUWU_COMMIT="73a25ec243a44ba2b1703e8d0a76fa2735062506"   # pinned for reproducibility
LINUWU_NAME="linuwu-sense"
LINUWU_VER="1.0.0"
LINUWU_SRC="/usr/src/${LINUWU_NAME}-${LINUWU_VER}"
TARGET_USER="$(id -un)"
TARGET_GROUP="$(id -gn)"

info "Installing kernel-module build toolchain (DKMS)"
xbps_install dkms gcc make git linux-headers

if dkms status 2>/dev/null | grep -q "^${LINUWU_NAME}/${LINUWU_VER}.*installed"; then
    info "linuwu-sense already installed via DKMS — skipping build"
else
    info "Fetching + building linuwu-sense via DKMS (pinned ${LINUWU_COMMIT:0:7})"
    _tmp="$(mktemp -d)"
    git clone "$LINUWU_REPO" "${_tmp}/Linuwu-Sense"
    git -C "${_tmp}/Linuwu-Sense" checkout -q "$LINUWU_COMMIT"
    rm -rf "${_tmp}/Linuwu-Sense/.git"

    sudo rm -rf "$LINUWU_SRC"
    sudo cp -a "${_tmp}/Linuwu-Sense" "$LINUWU_SRC"
    rm -rf "$_tmp"

    sudo tee "${LINUWU_SRC}/dkms.conf" >/dev/null <<EOF
PACKAGE_NAME="${LINUWU_NAME}"
PACKAGE_VERSION="${LINUWU_VER}"
BUILT_MODULE_NAME[0]="linuwu_sense"
BUILT_MODULE_LOCATION[0]="src"
DEST_MODULE_LOCATION[0]="/kernel/drivers/platform/x86"
MAKE[0]="make KVER=\${kernelver} all"
CLEAN="make KVER=\${kernelver} clean"
AUTOINSTALL="yes"
EOF

    sudo dkms add     -m "$LINUWU_NAME" -v "$LINUWU_VER"
    sudo dkms build   -m "$LINUWU_NAME" -v "$LINUWU_VER"
    sudo dkms install -m "$LINUWU_NAME" -v "$LINUWU_VER"
fi

info "Module config: blacklist stock acer_wmi, enable nitro_v4, autoload at boot"
sudo tee /etc/modprobe.d/linuwu-sense.conf >/dev/null <<'EOF'
blacklist acer_wmi
options linuwu_sense nitro_v4=1
EOF
echo "linuwu_sense" | sudo tee /etc/modules-load.d/linuwu-sense.conf >/dev/null

info "Installing acer-power daemon + waybar profile switcher"
sudo install -Dm755 "${ASSETS_DIR}/acer-power-manager"    /usr/local/bin/acer-power-manager
sudo install -Dm755 "${ASSETS_DIR}/acer-profile-switcher" /usr/local/bin/acer-profile-switcher

info "sudoers: let ${TARGET_USER} run acer-power-manager passwordless (waybar click)"
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/acer-power-manager\n' "$TARGET_USER" \
    | sudo tee /etc/sudoers.d/acer-power >/dev/null
sudo chmod 0440 /etc/sudoers.d/acer-power
sudo visudo -cf /etc/sudoers.d/acer-power >/dev/null || die "sudoers syntax check failed for acer-power"

info "State dir (${TARGET_USER}-writable override) + svlogd dir"
sudo install -d -o "$TARGET_USER" -g "$TARGET_GROUP" -m 0755 /var/lib/acer-power
sudo install -d -m 0755 /var/log/acer-power

info "runit service: acer-power (polls every 5s)"
sudo install -d /etc/sv/acer-power/log
sudo tee /etc/sv/acer-power/run >/dev/null <<'EOF'
#!/bin/sh
exec 2>&1
while :; do
    /usr/local/bin/acer-power-manager
    sleep 5
done
EOF
sudo tee /etc/sv/acer-power/log/run >/dev/null <<'EOF'
#!/bin/sh
exec svlogd -tt /var/log/acer-power
EOF
sudo chmod +x /etc/sv/acer-power/run /etc/sv/acer-power/log/run

info "Loading module now + enabling service"
sudo modprobe -r acer_wmi 2>/dev/null || true
sudo modprobe linuwu_sense nitro_v4=1 || warn "modprobe linuwu_sense failed — check: dmesg | grep -i linuwu"
sudo ln -sf /etc/sv/acer-power /var/service/

success "Acer Nitro thermal stack installed. Verify: cat /sys/firmware/acpi/platform_profile"
