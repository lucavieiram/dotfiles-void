#!/usr/bin/env bash
# log.sh — logging helpers for installer scripts
# Source this file; never execute directly.
#
# Provides: section, info, success, warn, err, die, ask_yes_no

# Locate the lib directory regardless of where this file is sourced from
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=colors.sh
. "${_LIB_DIR}/colors.sh"

section() {
    printf "\n%s%s═══ %s ═══%s\n" "$C_BOLD" "$C_CYAN" "$*" "$C_RESET"
}

info() {
    printf "%s[INFO]%s  %s\n" "$C_BLUE" "$C_RESET" "$*"
}

success() {
    printf "%s[ OK ]%s  %s\n" "$C_GREEN" "$C_RESET" "$*"
}

warn() {
    printf "%s[WARN]%s  %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2
}

err() {
    printf "%s[ERR ]%s  %s\n" "$C_RED" "$C_RESET" "$*" >&2
}

die() {
    err "$*"
    exit 1
}

# Dry-run mode: when DRY_RUN=1, override `sudo` to print what would
# have run, instead of running it. Phases see this transparently — they
# don't need to know about DRY_RUN. xbps_install (in xbps.sh) also
# respects it. Caveats: heredoc content piped to `sudo tee` is discarded,
# and `$(sudo …)` substitutions capture the dry-run banner string. We
# only use those patterns in xbps.sh, which handles DRY_RUN itself.
if [ "${DRY_RUN:-0}" = "1" ]; then
    sudo() {
        printf "%s[DRY ]%s  sudo %s\n" "$C_MAGENTA" "$C_RESET" "$*"
    }
    export -f sudo
fi

# ask_yes_no <prompt> [default-yes]
# Returns 0 for yes, 1 for no
ask_yes_no() {
    local prompt="$1"
    local default="${2:-no}"
    local hint reply
    if [ "$default" = "yes" ]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi
    while true; do
        printf "%s? %s " "$prompt" "$hint"
        read -r reply || reply=""
        reply="${reply:-$default}"
        case "$reply" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo])     return 1 ;;
            *) warn "Please answer yes or no." ;;
        esac
    done
}
