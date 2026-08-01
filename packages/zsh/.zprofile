# ~/.zprofile — kept intentionally minimal.
#
# Graphical-session env vars (XDG_CURRENT_DESKTOP, GDK_BACKEND, NIXOS_OZONE_WL,
# MOZ_ENABLE_WAYLAND, NVIDIA workarounds, EDITOR, BROWSER, etc.) live in
# /etc/environment and are loaded by PAM at login (pam_env.so). That way every
# program inherits them — sway, greetd, ssh, cron, the lot — without depending
# on a particular shell being your login shell.
#
# Sway is started by greetd. There's nothing to launch from here.

# Only-zsh tweaks (PATH, etc.) that aren't appropriate for /etc/environment:
export PATH="$HOME/.local/bin:$PATH"

# ssh-agent on a fixed socket. Passphrase-protected keys otherwise prompt on
# every connection — and non-interactive callers just fail outright.
# Fixed path (not the random /tmp one) so sway, new terminals and tools all
# share the one agent. Unlock once per boot:  ssh-add ~/.ssh/<your-key>
export SSH_AUTH_SOCK="$HOME/.ssh/agent/sock"
ssh-add -l >/dev/null 2>&1
if [ $? -eq 2 ]; then          # 2 = no agent reachable (1 = agent up, no keys)
    mkdir -p -m 700 "${SSH_AUTH_SOCK:h}"
    rm -f "$SSH_AUTH_SOCK"     # clear a socket left behind by a dead agent
    ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi
