#!/usr/bin/env bash
# cheatsheet.sh — fuzzel-based keybind reference (gruvbox).
# Usage: cheatsheet.sh [sway|nvim|tmux]  (default: sway)
# For sway, selecting an entry runs its bound action. For nvim/tmux the
# list is informational (commands typed inside the tool, not the shell).

set -u

ctx="${1:-sway}"

case "$ctx" in
    sway)
        prompt='   '
        entries=(
            "Super+Return            Open terminal                    | footclient"
            "Super+t                 Open terminal                    | footclient"
            "Super+b                 Open browser                     | brave-browser"
            "Super+c                 Open IDE (nvim)                  | footclient -e nvim"
            "Super+e                 Open file manager (yazi)         | footclient -e yazi"
            "Super+a                 App launcher                     | fuzzel"
            "Super+v                 Clipboard history                |"
            "Super+q                 Close window                     |"
            "Super+f                 Fullscreen                       |"
            "Super+Space             Floating toggle                  |"
            "Super+s                 Scratchpad show                  |"
            "Super+Shift+s           Send window to scratchpad        |"
            "Super+l                 Lock screen                      | ~/.local/bin/lock-now.sh"
            "Super+Shift+l           Layout toggle (split/tabbed)     |"
            "Super+Shift+w           Pick wallpaper                   | ~/.local/bin/wallpaper.sh select"
            "Super+Alt+Right         Next wallpaper                   | ~/.local/bin/wallpaper.sh next"
            "Super+Alt+Left          Previous wallpaper               | ~/.local/bin/wallpaper.sh prev"
            "Super+Shift+m           Monitor profile                  | ~/.local/bin/monitor-profile.sh"
            "Super+Shift+k           Switch keyboard layout           | ~/.local/bin/kb-layout-switch.sh"
            "Super+1..9              Go to workspace N                |"
            "Super+Shift+1..9        Move window to workspace N       |"
            "Super+Ctrl+Right        Next workspace                   |"
            "Super+Ctrl+Left         Previous workspace               |"
            "Super+H/J/K/Arrows      Focus left/down/up/direction     |"
            "Print                   Screenshot (full)                | ~/.local/bin/screenshot.sh all"
            "Super+p                 Screenshot (area)                | ~/.local/bin/screenshot.sh area"
            "Super+Shift+p           Color picker                     | ~/.local/bin/screenshot.sh color"
            "Ctrl+Alt+Del            Powermenu                        | ~/.local/bin/powermenu.sh"
            "Super+Shift+c           Reload Sway                      | swaymsg reload"
            "Super+/                 Sway cheatsheet                  | ~/.local/bin/cheatsheet.sh sway"
            "Super+Shift+/           Nvim cheatsheet                  | ~/.local/bin/cheatsheet.sh nvim"
            "Super+Ctrl+/            Tmux cheatsheet                  | ~/.local/bin/cheatsheet.sh tmux"
        )
        ;;
    nvim)
        prompt='   '
        entries=(
            "Space                   Which-key (discover bindings)    |"
            ":Lazy                   Plugin manager                   |"
            ":Mason                  LSP/formatter installer          |"
            ":checkhealth            Diagnose nvim setup              |"
            ""
            "[ Files / search ]                                       |"
            "Space + Space           Switch buffers (telescope)       |"
            "Space + ff              Find files                       |"
            "Space + sg              Live grep                        |"
            "Space + sb              Search current buffer            |"
            "Space + e               Toggle file explorer (neo-tree)  |"
            ""
            "[ LSP ]                                                  |"
            "gd                      Go to definition                 |"
            "gr                      Go to references                 |"
            "K                       Hover docs                       |"
            "Space + ca              Code actions                     |"
            "Space + rn              Rename symbol                    |"
            "Space + f               Format buffer                    |"
            "[d / ]d                 Prev / next diagnostic           |"
            ""
            "[ Edit / motion ]                                        |"
            "ciw                     Change inner word                |"
            "yy / dd                 Yank / delete line               |"
            "gcc                     Comment current line             |"
            "gc + motion             Comment a region                 |"
            "<C-d> / <C-u>           Half-page down / up              |"
            "%                       Jump to matching bracket         |"
            ""
            "[ Windows / tabs ]                                       |"
            "<C-w>s / <C-w>v         Horizontal / vertical split      |"
            "<C-w>hjkl               Move between splits              |"
            "<C-w>q                  Close split                      |"
            ":bd                     Close buffer                     |"
        )
        ;;
    tmux)
        prompt='   '
        entries=(
            "[ Prefix is Ctrl-a ]                                     |"
            ""
            "C-a |                   Split pane horizontally           |"
            "C-a -                   Split pane vertically             |"
            "C-a c                   New window                        |"
            "C-a n / p               Next / previous window            |"
            "C-a 0..9                Go to window N                    |"
            "C-a ,                   Rename current window             |"
            "C-a &                   Kill current window               |"
            "C-a x                   Kill current pane                 |"
            ""
            "[ Panes / navigation ]                                   |"
            "C-a h/j/k/l             Move focus (vim-like)             |"
            "C-a H/J/K/L             Resize pane by 5                  |"
            "C-a z                   Toggle pane zoom                  |"
            "C-a {/}                 Swap pane left / right            |"
            "C-a o                   Cycle through panes               |"
            "C-a Space               Cycle through layouts             |"
            ""
            "[ Sessions ]                                             |"
            "C-a d                   Detach session                    |"
            "C-a s                   Pick session                      |"
            "C-a $                   Rename session                    |"
            "tmux ls                 List sessions (in shell)          |"
            "tmux a -t <name>        Attach to session                 |"
            ""
            "[ Copy mode (vi keys) ]                                  |"
            "C-a [                   Enter copy mode                   |"
            "v                       Begin selection                   |"
            "C-v                     Rectangle selection               |"
            "y                       Yank to wl-clipboard              |"
            "q                       Quit copy mode                    |"
            ""
            "[ Misc ]                                                 |"
            "C-a r                   Reload ~/.tmux.conf               |"
            "C-a ?                   Built-in help (all binds)         |"
        )
        ;;
    *)
        echo "usage: $0 [sway|nvim|tmux]" >&2
        exit 64
        ;;
esac

selected=$(printf '%s\n' "${entries[@]}" | \
    fuzzel --dmenu \
           --prompt="$prompt" \
           --width=70 \
           --lines=22 \
           --font='JetBrainsMono Nerd Font:size=12')

[ -z "$selected" ] && exit 0

# Only sway entries have an action; nvim/tmux are informational.
cmd=$(printf '%s' "$selected" | awk -F'|' '{print $2}' | sed 's/^ *//;s/ *$//')
[ -n "$cmd" ] && eval "$cmd" &
