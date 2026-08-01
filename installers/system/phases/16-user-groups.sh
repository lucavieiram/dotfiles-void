#!/usr/bin/env bash
# 16-user-groups.sh — ensure user is in every group needed for the stack
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

USER_NAME="$(whoami)"

GROUPS_NEEDED=(
    wheel       # sudo
    audio       # pipewire audio devices
    video       # pipewire video, webcam, GPU
    input       # input devices
    storage     # removable storage
    network     # NetworkManager / wpa_supplicant
    plugdev     # pluggable devices
    _seatd      # seatd seat manager
    lp          # CUPS printing (admin printers via web UI / lpadmin)
)

# Conditional groups (only add if the group exists — created by their packages)
CONDITIONAL_GROUPS=(
    docker
    bluetooth   # created by bluez (05-audio.sh)
    bumblebee   # only if bumblebee installed (we don't, using prime-run)
)

info "Adding ${USER_NAME} to baseline groups"
for grp in "${GROUPS_NEEDED[@]}"; do
    if getent group "$grp" >/dev/null; then
        sudo usermod -aG "$grp" "$USER_NAME"
        info "  + $grp"
    else
        warn "  ! group $grp does not exist on this system; skipping"
    fi
done

info "Adding ${USER_NAME} to conditional groups (only if installed)"
for grp in "${CONDITIONAL_GROUPS[@]}"; do
    if getent group "$grp" >/dev/null; then
        sudo usermod -aG "$grp" "$USER_NAME"
        info "  + $grp"
    fi
done

success "Group membership applied (effective after next login)"
info "Verify with: groups"
