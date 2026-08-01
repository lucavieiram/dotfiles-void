#!/usr/bin/env bash
# sandbox-cmd — run an untrusted command in a bubblewrap sandbox that has
# no access to credentials/keys/SSH/cloud configs. Intended for installing
# or running third-party code (npm/pnpm/pip/uv/cargo/go) where supply-chain
# attacks via post-install scripts are a real risk.
#
# What's blocked (replaced with empty tmpfs):
#   ~/.ssh         ~/.gnupg        ~/.aws         ~/.kube
#   ~/.config/sops ~/.config/gh    ~/.docker      ~/.netrc
#   ~/.mozilla     ~/.config/Brave-Browser
#
# What's preserved:
#   read-only host root
#   read-write current directory ($PWD) — for installing into node_modules etc.
#   /tmp (own tmpfs), /dev, /proc, network access
#
# The sandbox dies if you Ctrl-C the parent. New PID namespace, new session.
#
# Examples:
#   sandbox-cmd npm install
#   sandbox-cmd pnpm install some-untrusted-pkg
#   sandbox-cmd pip install --user something
#   sandbox-cmd bash -c './configure && make'
#   sandbox-cmd cargo build
#
# Caveat: this is a sandbox, not a panacea. A determined attacker can still
# exfiltrate via network. Pair with `--ignore-scripts` (npm) or run offline
# (`--unshare-net` would block network entirely) for higher assurance.

set -euo pipefail

if [ "$#" -lt 1 ]; then
    cat <<EOF
usage: sandbox-cmd <command> [args...]

Runs <command> in a bubblewrap sandbox without access to ~/.ssh, ~/.gnupg,
~/.aws, ~/.kube, ~/.config/sops, ~/.config/gh, ~/.docker, ~/.netrc, browser
profiles, etc. \$PWD is bind-mounted read-write so installers can write into
node_modules/, .venv/, etc.

For maximum paranoia, add --no-network as the first flag:
  sandbox-cmd --no-network npm install
EOF
    exit 2
fi

NET_ARG="--share-net"
if [ "$1" = "--no-network" ]; then
    NET_ARG="--unshare-net"
    shift
fi

# Hide-list — anything under \$HOME that holds secrets/credentials.
# Each item becomes a tmpfs mount that masks the real directory.
HIDE_PATHS=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.aws"
    "$HOME/.kube"
    "$HOME/.config/sops"
    "$HOME/.config/gh"
    "$HOME/.docker"
    "$HOME/.netrc"
    "$HOME/.mozilla"
    "$HOME/.config/google-chrome"
    "$HOME/.config/BraveSoftware"
    "$HOME/.config/chromium"
    "$HOME/.config/keepassxc"
    "$HOME/.local/share/keyrings"
    "$HOME/.config/Mullvad VPN"
)

ARGS=(
    --ro-bind / /
    --dev /dev
    --proc /proc
    --tmpfs /tmp
    --tmpfs /var/tmp
    --bind "$PWD" "$PWD"
    --chdir "$PWD"
    --unshare-pid
    --new-session
    --die-with-parent
    "$NET_ARG"
)

# Add a tmpfs mask for each sensitive path that actually exists.
for p in "${HIDE_PATHS[@]}"; do
    [ -e "$p" ] && ARGS+=( --tmpfs "$p" )
done

exec bwrap "${ARGS[@]}" -- "$@"
