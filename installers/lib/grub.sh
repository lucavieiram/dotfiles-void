#!/usr/bin/env bash
# grub.sh — idempotent helpers for editing /etc/default/grub
# Source after log.sh.

# grub_add_cmdline <param>
# Adds <param> to GRUB_CMDLINE_LINUX_DEFAULT if not already present, then
# regenerates grub.cfg. Idempotent — safe to call from multiple phases.
grub_add_cmdline() {
    local param="$1"
    local grub_file="/etc/default/grub"

    if [ ! -f "$grub_file" ]; then
        warn "$grub_file not found — skipping cmdline param: $param"
        return 0
    fi

    if grep -E "^GRUB_CMDLINE_LINUX_DEFAULT=.*\b${param//./\\.}" "$grub_file" >/dev/null; then
        info "GRUB cmdline already has: $param"
        return 0
    fi

    info "Adding to GRUB cmdline: $param"
    sudo sed -i -E \
        "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\")(.*)(\")|\1\2 ${param}\3|" \
        "$grub_file"

    # Squash double spaces from previous additions
    sudo sed -i -E 's|GRUB_CMDLINE_LINUX_DEFAULT="  *|GRUB_CMDLINE_LINUX_DEFAULT="|' "$grub_file"
}

# grub_regenerate
# Runs the appropriate grub config regeneration command.
grub_regenerate() {
    info "Regenerating grub.cfg"
    if command -v update-grub >/dev/null 2>&1; then
        sudo update-grub
    elif [ -d /boot/grub ]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -d /boot/efi/EFI ]; then
        local cfg
        cfg="$(find /boot/efi/EFI -name grub.cfg -print -quit)"
        [ -n "$cfg" ] && sudo grub-mkconfig -o "$cfg" || warn "Could not locate grub.cfg"
    else
        warn "No GRUB installation detected — skipping regeneration"
    fi
}
