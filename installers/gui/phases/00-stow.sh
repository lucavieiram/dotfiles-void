#!/usr/bin/env bash
# 00-stow.sh — symlink every package under packages/ into $HOME
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/stow.sh"

info "Stowing dotfiles packages into \$HOME"
stow_all
