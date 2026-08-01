#!/usr/bin/env bash
# installers/gui/install.sh — graphical environment setup
# Invoked via ./install.sh gui
#
# Iterates installers/gui/phases/[0-9][0-9]-*.sh in order. Each phase is
# independently runnable.

set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export REPO_DIR

# shellcheck source=../lib/log.sh
. "${REPO_DIR}/installers/lib/log.sh"

PHASES_DIR="$(dirname "${BASH_SOURCE[0]}")/phases"

section "dotfiles-void :: gui environment"

# Pre-flight
if [ "$(id -u)" -eq 0 ]; then
    die "Run as your regular user. Do not run as root."
fi

if [ ! -d "${REPO_DIR}/packages" ]; then
    die "packages/ directory missing. Repo layout is broken."
fi

shopt -s nullglob
phases=( "$PHASES_DIR"/[0-9][0-9]-*.sh )
shopt -u nullglob

[ "${#phases[@]}" -gt 0 ] || die "No phase scripts in $PHASES_DIR"

for phase in "${phases[@]}"; do
    section "$(basename "$phase" .sh)"
    bash "$phase"
done

section "done"
success "GUI environment installed."
info ""
info "Next steps:"
info "  1. swaymsg reload         (or logout + log back into Sway)"
info "  2. Verify Super+/ opens the cheatsheet"
info "  3. Add your own wallpapers to ~/Pictures/Wallpapers/ then Super+Shift+W"
