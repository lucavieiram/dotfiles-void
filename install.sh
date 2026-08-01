#!/usr/bin/env bash
# install.sh — dotfiles-void entry point
#
# Usage:
#   ./install.sh [--dry-run] void      Install system layer (sudo)
#   ./install.sh [--dry-run] gui       Install graphical environment (user)
#   ./install.sh help                  Show this help
#
# Run `void` first, reboot, then `gui` after logging into Sway.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

# shellcheck source=installers/lib/log.sh
. "${REPO_DIR}/installers/lib/log.sh"

usage() {
    cat <<EOF
dotfiles-void installer

Usage:
    ./install.sh [--dry-run] <command>

Commands:
    void        Install system packages, drivers, services on Void Linux
                Run this once on a fresh Void base install. Uses sudo.
    gui         Install graphical environment (Sway, dotfiles, plugins)
                Run as your regular user, after rebooting into Sway.
    help        Show this message

Flags:
    --dry-run   Print what each phase would do (xbps installs + sudo
                commands) without actually running them. Lets you audit
                changes before committing to them. Caveat: side-effects
                that bypass the sudo wrapper (e.g. direct file writes
                in \$HOME) still happen.

Recommended order:
    1. ./install.sh --dry-run void   # audit first
    2. ./install.sh void
    3. sudo reboot
    4. log in via greetd into Sway
    5. ./install.sh gui
    6. swaymsg reload

Repo: ${REPO_DIR}
EOF
}

# Parse optional --dry-run flag (must come before the command)
if [ "${1:-}" = "--dry-run" ]; then
    export DRY_RUN=1
    warn "DRY RUN — no packages will be installed, no sudo commands will run"
    shift
fi

case "${1:-help}" in
    void)
        info "Starting Void system installation"
        exec "${REPO_DIR}/installers/system/install.sh"
        ;;
    gui)
        info "Starting GUI environment installation"
        exec "${REPO_DIR}/installers/gui/install.sh"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        err "Unknown command: $1"
        usage
        exit 64
        ;;
esac
