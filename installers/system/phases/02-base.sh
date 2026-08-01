#!/usr/bin/env bash
# 02-base.sh — base CLI utilities every system needs
set -euo pipefail
. "${REPO_DIR}/installers/lib/log.sh"
. "${REPO_DIR}/installers/lib/xbps.sh"

info "Installing base CLI tooling"
xbps_install \
    git curl wget rsync openssh \
    stow tmux \
    htop btop tree file unzip xz zip 7zip \
    bash-completion \
    man-pages less \
    pciutils usbutils lshw \
    ImageMagick \
    fastfetch \
    cronie

info "Enabling cron service"
sudo ln -sf /etc/sv/crond /var/service/

success "Base utilities installed"
