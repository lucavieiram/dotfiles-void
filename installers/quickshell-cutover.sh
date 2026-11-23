#!/usr/bin/env bash
# quickshell-cutover.sh — switch the desktop from Waybar/dunst/applets to the Quickshell shell.
#
#   installers/quickshell-cutover.sh            do it (backs up every live file it edits)
#   installers/quickshell-cutover.sh --undo     restore the backups and the old autostart
#
# What it does:
#   1. links packages/quickshell, packages/theme, the new sway/gtk/nvim files (stow --restow)
#   2. autostart: waybar line -> `exec qs`; dunst, nm-applet, blueman-applet commented out
#   3. qt6ct: style=Fusion (gtk2 style ignores palettes), custom_palette=true, scheme -> theme cache
#   4. gtklock: @import of ~/.cache/theme/gtklock.css
#   5. dunst D-Bus auto-start masked (user override), adw-gtk3 installed to ~/.local/share/themes
#   6. starts qs, checks it came up, THEN stops waybar/dunst/applets
# The waybar/dunst/fuzzel packages stay in the repo; delete them later by hand once happy.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$REPO/packages"
BAK=".pre-quickshell"
AUTOSTART="$PKG/sway/.config/sway/config.d/50-autostart.conf"
QT6CT="$PKG/qt/.config/qt6ct/qt6ct.conf"
GTKLOCK="$PKG/gtklock/.config/gtklock/style.css"
EDITED=("$AUTOSTART" "$QT6CT" "$GTKLOCK")
DUNST_MASK="$HOME/.local/share/dbus-1/services/org.knopwob.dunst.service"

stop_old() {
    pkill -x waybar 2>/dev/null || true
    pkill -x dunst 2>/dev/null || true
    pkill -x nm-applet 2>/dev/null || true
    pkill -f blueman-applet 2>/dev/null || true
    for _ in $(seq 1 30); do pgrep -x dunst >/dev/null || break; sleep 0.1; done
}

stop_qs() {
    pkill -x qs 2>/dev/null || true
    pkill -x quickshell 2>/dev/null || true
}

undo() {
    for f in "${EDITED[@]}"; do
        [ -f "$f$BAK" ] && mv "$f$BAK" "$f" && echo "restored $f"
    done
    rm -f "$DUNST_MASK"
    stow -d "$PKG" -t "$HOME" -D quickshell 2>/dev/null || true
    rm -f "$HOME/.config/sway/config.d/45-shell.conf" "$HOME/.config/gtk-3.0/gtk.css" \
          "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/nvim/lua/plugins/theme.lua"
    stop_qs
    stop_old   # avoid doubles if a half-done cutover left some running
    swaymsg reload >/dev/null || true
    swaymsg -q 'exec dunst; exec nm-applet --indicator; exec blueman-applet; exec waybar'
    echo "undone: waybar/dunst/applets are back."
    echo "note: packages/sway still holds config.d/45-shell.conf; a later 'stow --restow sway'"
    echo "      relinks it and Super+A would call qs. Move that file aside if you stay on waybar."
}

[ "${1:-}" = "--undo" ] && { undo; exit 0; }

for f in "${EDITED[@]}"; do
    [ -f "$f$BAK" ] && { echo "backup $f$BAK already exists; run --undo first" >&2; exit 1; }
done
command -v qs >/dev/null || { echo "qs not installed: sudo xbps-install quickshell" >&2; exit 1; }

# 1. links
stow -d "$PKG" -t "$HOME" quickshell theme
stow -d "$PKG" -t "$HOME" --restow sway gtk nvim

# 2. autostart (exact-line edits only)
cp "$AUTOSTART" "$AUTOSTART$BAK"
python3 - "$AUTOSTART" <<'P'
import sys, re
p = sys.argv[1]; t = open(p).read()
t = re.sub(r"^exec sh -c 'for i in \$\(seq 1 40\).*waybar'$",
           "# Quickshell shell (packages/quickshell); replaced waybar 2026-11-22\nexec qs", t, flags=re.M)
for cmd in ("exec dunst", "exec nm-applet --indicator", "exec blueman-applet"):
    t = re.sub(rf"^{re.escape(cmd)}$", f"# {cmd}  # replaced by Quickshell", t, flags=re.M)
open(p, "w").write(t)
P

# 3. qt6ct
cp "$QT6CT" "$QT6CT$BAK"
sed -i 's/^style=.*/style=Fusion/; s/^custom_palette=.*/custom_palette=true/' "$QT6CT"
if grep -q '^color_scheme_path=' "$QT6CT"; then
    sed -i "s|^color_scheme_path=.*|color_scheme_path=$HOME/.cache/theme/qt6ct.conf|" "$QT6CT"
else
    sed -i "/^custom_palette=/a color_scheme_path=$HOME/.cache/theme/qt6ct.conf" "$QT6CT"
fi

# 4. gtklock (template uses higher-specificity selectors, so position does not matter)
cp "$GTKLOCK" "$GTKLOCK$BAK"
sed -i "1i @import url(\"file://$HOME/.cache/theme/gtklock.css\");" "$GTKLOCK"

# 5a. stop D-Bus from auto-starting dunst when nobody owns the notification name
mkdir -p "$(dirname "$DUNST_MASK")"
printf '[D-BUS Service]\nName=org.freedesktop.Notifications\nExec=/bin/false\n' > "$DUNST_MASK"

# 5b. adw-gtk3 (not packaged for Void) so GTK3 apps take the theme colours
if [ ! -d "$HOME/.local/share/themes/adw-gtk3-dark" ]; then
    url=$(curl -fsSL https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest \
          | grep -o '"browser_download_url": *"[^"]*\.tar\.xz"' | head -1 | cut -d'"' -f4) || url=""
    if [ -n "$url" ]; then
        mkdir -p "$HOME/.local/share/themes"
        curl -fsSL "$url" | tar -xJ -C "$HOME/.local/share/themes" \
            && echo "installed adw-gtk3 from $url" || echo "warn: adw-gtk3 download failed" >&2
    else
        echo "warn: could not find the adw-gtk3 release; GTK3 apps keep Adwaita colours" >&2
    fi
fi

# re-render the current theme so every new target gets its file
theme-apply "$(python3 -c 'import json,os; print(json.load(open(os.path.expanduser("~/.cache/theme/current.json")))["spec"])' 2>/dev/null || echo gruvbox-dark)"

# 6. start qs first; only remove the old bar once qs is confirmed running
swaymsg reload >/dev/null || true
stop_old        # dunst must release the notification name before qs registers
swaymsg -q 'exec qs'
sleep 3
if ! pgrep -x qs >/dev/null && ! pgrep -x quickshell >/dev/null; then
    echo "qs did not start; rolling back" >&2
    undo
    exit 1
fi
echo "done. Undo: $0 --undo"
