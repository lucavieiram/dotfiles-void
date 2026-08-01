#!/usr/bin/env bash
# 01-repos.sh — enable nonfree (NVIDIA, firmware) and multilib (32-bit) repos
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"

info "Enabling nonfree repository (NVIDIA drivers, firmware blobs)"
sudo xbps-install -Sy void-repo-nonfree
sudo xbps-install -Sy

info "Enabling multilib repository (32-bit support for Steam/Proton)"
sudo xbps-install -Sy void-repo-multilib void-repo-multilib-nonfree
sudo xbps-install -Sy

success "Repositories enabled"
