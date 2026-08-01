#!/usr/bin/env bash
# 01-zsh-plugins.sh — clone the 3 zsh plugins referenced by .zshrc
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

PLUGINS_DIR="$HOME/.zsh"
mkdir -p "$PLUGINS_DIR"

declare -A PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [zsh-completions]="https://github.com/zsh-users/zsh-completions"
)

for name in "${!PLUGINS[@]}"; do
    url="${PLUGINS[$name]}"
    target="${PLUGINS_DIR}/${name}"
    if [ -d "${target}/.git" ]; then
        info "Updating ${name}"
        git -C "$target" pull --ff-only --quiet || warn "  could not fast-forward $name"
    else
        info "Cloning ${name}"
        git clone --depth=1 --quiet "$url" "$target"
    fi
done

success "zsh plugins ready"
