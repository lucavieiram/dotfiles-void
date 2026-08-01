#!/usr/bin/env bash
# 00-update.sh — refresh xbps and update the base system
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

info "Updating xbps and base system"
sudo xbps-install -Sy xbps
sudo xbps-install -Suy
success "Base system up to date"
