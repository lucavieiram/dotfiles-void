#!/usr/bin/env bash
# 09-shell-editor.sh — zsh, neovim, CLI productivity tools
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing shell + editor + productivity CLIs"
xbps_install \
    zsh starship \
    neovim \
    eza fd ripgrep fzf bat git-delta delta \
    jq yq-go \
    zoxide direnv
# gh (GitHub CLI) not in Void repos; install via release tarball if needed:
#   https://github.com/cli/cli/releases

# LazyVim dependencies for full functionality
info "Installing LazyVim build deps (LSP servers, formatters)"
xbps_install \
    nodejs \
    python3 python3-pip \
    go \
    luarocks luarocks-lua51 \
    tree-sitter \
    lazygit

info "Setting zsh as default shell for $(whoami)"
if command -v zsh >/dev/null 2>&1; then
    if [ "$(getent passwd "$(whoami)" | cut -d: -f7)" != "/bin/zsh" ]; then
        sudo chsh -s /bin/zsh "$(whoami)" || warn "chsh failed — set manually with: sudo chsh -s /bin/zsh $(whoami)"
    fi
else
    warn "zsh not installed — skipping chsh"
fi

success "Shell + editor stack ready"
