#!/usr/bin/env bash
# xbps.sh — helper for tolerant xbps-install
# Source after log.sh.

# xbps_install <pkg> [pkg ...]
# Installs each package individually so a single missing/unavailable package
# doesn't abort the entire phase. Reports skipped packages at the end.
# Respects DRY_RUN=1: prints the package list instead of installing.
xbps_install() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf "%s[DRY ]%s  xbps-install: %s\n" "$C_MAGENTA" "$C_RESET" "$*"
        return 0
    fi
    local pkg failed=()
    for pkg in "$@"; do
        if ! command sudo xbps-install -y "$pkg" >/dev/null 2>&1; then
            # Check whether the package is "already installed" (fine) or missing
            local out
            out=$(command sudo xbps-install -y "$pkg" 2>&1 || true)
            if echo "$out" | grep -qi "already installed"; then
                : # silently skip — already there
            elif echo "$out" | grep -qi "not found in repository pool"; then
                failed+=("$pkg")
                warn "  skipped (not in repo): $pkg"
            else
                # Other error — print it so user can see
                err   "  failed: $pkg"
                printf '%s\n' "$out" | sed 's/^/        /' >&2
                failed+=("$pkg")
            fi
        fi
    done
    if [ "${#failed[@]}" -gt 0 ]; then
        warn "Skipped/failed packages (${#failed[@]}): ${failed[*]}"
    fi
}
