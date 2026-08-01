# Scripts reference

All scripts live in `packages/scripts/.local/bin/` and stow into `~/.local/bin/`. Each is self-contained and runnable independently.

## Inventory

| Script               | Bind                              | Purpose |
|----------------------|-----------------------------------|---------|
| `cheatsheet.sh`      | `Super+/`                         | Render markdown cheatsheet in floating foot |
| `kb-layout-switch.sh`| `Super+K`                         | Cycle keyboard layouts via `swaymsg input` |
| `lock-now.sh`        | `Super+L` (+ swayidle)            | gtklock with blurred current wallpaper + big clock |
| `monitor-profile.sh` | `Super+Shift+M`                   | Switch laptop / dual / external monitor profiles |
| `powermenu.sh`       | `Ctrl+Alt+Del`                    | Launch `wlogout` overlay |
| `screenshot.sh`      | `Super+P`, `Super+Shift+P`, etc.  | area / window / monitor / all / frozen / color modes |
| `wallpaper.sh`       | `Super+Shift+W`, `Super+Alt+←/→` | `select` (fuzzel picker), `next`, `prev`, `random` |
| `wifi.sh`            | —                                 | `list` / `connect` / `forget` / `current` / `on` / `off` — nmcli wrapper |
| `mullvad.sh`         | —                                 | `import` / `up` / `down` / `list` / `status` — Mullvad WireGuard via NM |
| `sandbox-cmd.sh`     | —                                 | bubblewrap wrapper that hides ~/.ssh, ~/.gnupg, ~/.aws, browser profiles, etc. Use for untrusted code: `sandbox-cmd npm install`, `sandbox-cmd pip install foo`. Add `--no-network` for offline. |

Plus one helper script (not user-facing):

| Script                | Used by             | Purpose |
|-----------------------|---------------------|---------|
| `waybar-ws-icons.py`  | waybar `custom/sway-ws` (legacy) | Per-app workspace icons via sway IPC. The active config uses native `sway/workspaces` with `window-rewrite`, so this script may be removable. |

## Conventions

Each script:

- Starts with `#!/usr/bin/env bash` + `set -euo pipefail`
- Has a short header comment block: purpose + dependencies (one-line max)
- Uses `notify-send` for user-visible notifications
- Calls `swaymsg` for compositor queries
- Uses `fuzzel --dmenu` for picker UIs
- Reads/writes its own state under `${XDG_STATE_HOME:-~/.local/state}/`
