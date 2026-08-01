#!/usr/bin/env bash
# 04-nvim-sync.sh — bootstrap LazyVim plugins headlessly.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

if ! command -v nvim >/dev/null; then
    warn "nvim not installed; skipping LazyVim sync"
    exit 0
fi

info "Running headless LazyVim plugin sync (may take a few minutes on first run)"
if timeout 300 nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
    success "LazyVim plugins synced"
else
    warn "LazyVim sync did not complete in 5 minutes. Run manually:"
    warn "    nvim   →   :Lazy sync"
fi
