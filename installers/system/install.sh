#!/usr/bin/env bash
# installers/system/install.sh — system-level Void Linux setup
# Invoked via ./install.sh void
#
# Runs modular phase scripts under phases/ in order.
# Each phase is independently runnable. To run a single phase:
#     ./installers/system/phases/02-gpu.sh

set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export REPO_DIR

# shellcheck source=../lib/log.sh
. "${REPO_DIR}/installers/lib/log.sh"

PHASES_DIR="$(dirname "${BASH_SOURCE[0]}")/phases"

section "dotfiles-void :: system installation"

# Pre-flight checks
if [ "$(id -u)" -eq 0 ]; then
    die "Run as your regular user (script uses sudo where needed). Do not run as root."
fi

if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required. Install: su -c 'xbps-install -y sudo && usermod -aG wheel $(whoami)'"
fi

# Verify Void
if ! command -v xbps-install >/dev/null 2>&1; then
    die "xbps-install not found. This installer targets Void Linux only."
fi

# Confirmation
warn "This will modify system packages, drivers, and services."
warn "Phases run in order under: ${PHASES_DIR}"
if ! ask_yes_no "Proceed with system installation"; then
    info "Aborted by user."
    exit 0
fi

# Iterate phase scripts
if [ ! -d "$PHASES_DIR" ]; then
    die "Phases directory not found: $PHASES_DIR  (Phases will be added in later commits.)"
fi

shopt -s nullglob
phases=( "$PHASES_DIR"/[0-9][0-9]-*.sh )
shopt -u nullglob

if [ "${#phases[@]}" -eq 0 ]; then
    warn "No phase scripts found yet. Nothing to do."
    exit 0
fi

for phase in "${phases[@]}"; do
    section "$(basename "$phase" .sh)"
    bash "$phase"
done

success "System installation complete. Reboot, then run: ./install.sh gui"
