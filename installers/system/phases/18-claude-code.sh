#!/usr/bin/env bash
# 18-claude-code.sh — Install Claude Code CLI (npm global)
# Requires nodejs from 09-shell-editor.sh.
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

if ! command -v npm >/dev/null; then
    warn "npm not installed — install nodejs first (09-shell-editor.sh)"
    exit 0
fi

info "Installing Claude Code (@anthropic-ai/claude-code) globally via npm"
sudo npm install -g @anthropic-ai/claude-code || \
    warn "npm install failed — retry manually: sudo npm install -g @anthropic-ai/claude-code"

if command -v claude >/dev/null; then
    info "Claude Code installed: $(claude --version 2>/dev/null || echo 'version check pending')"
else
    warn "claude binary not in PATH — check /usr/local/bin or /usr/bin"
fi

# Create ~/.claude config dir if not present (Claude Code uses this for state/sessions)
mkdir -p "$HOME/.claude"
chmod 700 "$HOME/.claude"

success "Claude Code ready. First run: claude (in any project directory)"
info ""
info "To resume an existing session (after restoring ~/.claude from backup):"
info "    cd <project-dir> && claude --resume"
