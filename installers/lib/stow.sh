#!/usr/bin/env bash
# stow.sh — idempotent stow helpers
# Source this file. Requires log.sh already sourced.
#
# Provides:
#   stow_pkg <pkg>             Stow a single package from packages/ into $HOME
#   stow_all                   Stow every directory under packages/
#   unstow_pkg <pkg>           Unstow a single package
#   unstow_all                 Unstow every package

# Where stow packages live, relative to REPO_DIR
STOW_SOURCE_DIR="${REPO_DIR}/packages"

_require_stow() {
    if ! command -v stow >/dev/null 2>&1; then
        die "GNU Stow is required but not installed. Install: sudo xbps-install -y stow"
    fi
}

stow_pkg() {
    _require_stow
    local pkg="$1"
    [ -d "${STOW_SOURCE_DIR}/${pkg}" ] || die "Unknown package: ${pkg}"
    info "Stowing ${pkg}"
    # -R = restow (idempotent: removes old links then relinks)
    # --no-folding = always create dirs, never link a whole subtree (safer)
    if ! stow -d "${STOW_SOURCE_DIR}" -t "$HOME" -R --no-folding "$pkg" 2>&1 | sed "s/^/    /"; then
        err "Failed to stow ${pkg}"
        warn "Resolve conflicts manually (move/remove the existing file) and rerun."
        return 1
    fi
}

stow_all() {
    _require_stow
    local pkg failed=0
    for dir in "${STOW_SOURCE_DIR}"/*/; do
        pkg="$(basename "$dir")"
        # Skip the directory if it only has a .gitkeep (empty package)
        if [ "$(find "$dir" -mindepth 1 -not -name '.gitkeep' | head -1)" = "" ]; then
            warn "Skipping empty package: ${pkg}"
            continue
        fi
        stow_pkg "$pkg" || failed=$((failed + 1))
    done
    if [ "$failed" -gt 0 ]; then
        die "${failed} package(s) failed to stow"
    fi
    success "All packages stowed"
}

unstow_pkg() {
    _require_stow
    local pkg="$1"
    [ -d "${STOW_SOURCE_DIR}/${pkg}" ] || die "Unknown package: ${pkg}"
    info "Unstowing ${pkg}"
    stow -d "${STOW_SOURCE_DIR}" -t "$HOME" -D "$pkg"
}

unstow_all() {
    _require_stow
    local pkg
    for dir in "${STOW_SOURCE_DIR}"/*/; do
        pkg="$(basename "$dir")"
        unstow_pkg "$pkg" || true
    done
    success "All packages unstowed"
}
