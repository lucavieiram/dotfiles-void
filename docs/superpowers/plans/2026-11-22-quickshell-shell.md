# Quickshell Desktop Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One self-written Quickshell shell (pill bar, left theme/wallpaper panel, right control center, notifications, launcher) on Sway, plus a theme engine that recolours the whole system.

**Architecture:** A Python `apply` script turns a palette JSON into small colour fragments in `~/.cache/theme/` that each app includes; Quickshell reads the same `current.json` live. QML is split one file per widget; all Sway-specific code lives in `compositor/Sway.qml`.

**Tech Stack:** Quickshell 0.3.2 (`qs`), QML/Qt 6.11, Python 3 stdlib (`apply` + `unittest`), matugen 4.2.0, swaybg, GNU stow (`dotfiles-void/packages/*`).

**Spec:** `docs/superpowers/specs/2026-11-22-quickshell-shell-design.md`

## Global Constraints

- Repo `~/Code/dotfiles-void`; new stow packages `packages/quickshell` (-> `~/.config/quickshell/`) and `packages/theme` (-> `~/.config/theme/` + `~/.local/bin/theme-apply`).
- Generated files only in `~/.cache/theme/`; never stowed, never in git.
- Hand-written app configs are never fully replaced; they gain one include line.
- Five themes: `gruvbox-dark` (default, equals today's colours, from `20-colors.conf` + `waybar/tokens/colors.css`), `gruvbox-light`, `catppuccin-mocha`, `everforest-dark`, `nord`.
- Font: `JetBrainsMono Nerd Font`. No emojis.
- Shell started by Sway `exec qs`, no systemd.
- Workspace glyphs verbatim from `packages/waybar/.config/waybar/modules/workspace.jsonc`: focused `󰮯`, default `󰊠`, urgent `󰧵`, plus its `window-rewrite` map.
- Panels open on the focused output. Old waybar/dunst/fuzzel packages stay in the repo until Task 9, then are removed.
- Do not `git commit` unless the user asks. Undo only your own lines, never `git checkout -- <file>`.
- Install needs root: the user runs `sudo xbps-install -S quickshell matugen brightnessctl` themselves.

## Review Focus

1. Palette JSON missing a key -> `apply` exits non-zero naming the key, writes nothing (test in Task 1).
2. Theme applied while Quickshell is not running -> files still written, no error (test in Task 1).
3. Unplugging HDMI-A-2 -> bar on eDP-1 survives, no crash (check in Task 2).
4. Workspace with an app missing from the icon map -> default glyph `` shown (test in Task 3).
5. `--wallpaper` on a file matugen cannot read -> previous theme kept, error printed (test in Task 1).

---

### Task 1: Theme engine

**Files:**
- Create: `packages/theme/.config/theme/palettes/{gruvbox-dark,gruvbox-light,catppuccin-mocha,everforest-dark,nord}.json`
- Create: `packages/theme/.config/theme/templates/{foot.ini,sway.conf,gtk.css,qt6ct.conf,gtklock.css}.tmpl`
- Create: `packages/theme/.local/bin/theme-apply` (Python 3, executable)
- Test: `packages/theme/.config/theme/test_apply.py`

**Interfaces:**
- Produces: palette keys `name, mode(dark|light), bg0, bg1, bg2, bg3, fg, fg_dim, accent, red, orange, yellow, green, aqua, blue, purple, nvim_colorscheme, btop_theme`; output `~/.cache/theme/current.json` (palette + `"wallpaper": <path>`), plus `foot.ini, sway.conf, gtk.css, qt6ct.conf, gtklock.css, nvim.lua, btop.theme_name`; state `~/.cache/theme/previous`.
- CLI: `theme-apply <name>` | `theme-apply --wallpaper <file>` | `theme-apply --previous` | `theme-apply --list` (one name per line).
- Env override for tests: `THEME_HOME` (palettes/templates root), `THEME_CACHE` (output dir), `THEME_DRY=1` (skip reload commands).

- [ ] **Step 1: Write failing tests** `test_apply.py` (unittest, tmp dirs via env vars):
  - `test_list_returns_five_themes`: `--list` prints exactly the 5 names, sorted.
  - `test_apply_writes_all_fragments`: after `gruvbox-light`, every output file above exists and `current.json["name"] == "gruvbox-light"`.
  - `test_template_substitution`: rendered `sway.conf` contains the palette's `accent` hex and no `${`.
  - `test_missing_key_writes_nothing`: palette without `accent` -> exit code != 0, stderr contains `accent`, cache dir unchanged.
  - `test_previous_reverts`: apply A, apply B, `--previous` -> `current.json["name"] == A`.
  - `test_bad_wallpaper_keeps_theme`: `--wallpaper /nonexistent.png` -> exit != 0, `current.json` unchanged.
  - `test_no_quickshell_running_ok`: with `THEME_DRY=1` unset but reload commands absent from PATH, exit 0.
- [ ] **Step 2:** `python3 -m unittest packages/theme/.config/theme/test_apply.py` -> FAIL (no script).
- [ ] **Step 3: Implement `theme-apply`.** `string.Template` for templates; write all outputs to a temp dir then `os.replace` each (atomic, so a failure writes nothing). `--wallpaper`: run `matugen image <file> --json hex`, map its Material roles onto palette keys (`surface`->bg0, `surface_container`->bg1/bg2, `on_surface`->fg, `primary`->accent; keep the accent colours from `gruvbox-dark` for red..purple), `nvim_colorscheme`/`btop_theme` follow `mode`. Reload (skipped when `THEME_DRY=1`, each failure ignored): `swaymsg reload`; `pkill -USR1 ...` none needed for Quickshell (it watches the file); OSC 4/10/11 sequences to each `/dev/pts/*` owned by the user running foot; `swaybg` restart with the wallpaper; `gsettings set org.gnome.desktop.interface color-scheme prefer-dark|prefer-light`.
- [ ] **Step 4:** Unit tests -> all PASS.
- [ ] **Step 5: Palettes.** `gruvbox-dark` copies today's hexes (`#1d2021, #282828, #3c3836, #504945, #ebdbb2, #a89984`, accent `#478061`, red `#cc241d`). The other four from their upstream palettes; record the source URL in a `"source"` key.

### Task 2: Wire apps to the fragments + Quickshell skeleton

**Files:**
- Modify: `packages/foot/.config/foot/foot.ini` (add `include=~/.cache/theme/foot.ini`)
- Modify: `packages/sway/.config/sway/config.d/20-colors.conf` (replace the 4 `client.*` lines with `include ~/.cache/theme/sway.conf`; keep the file's header comment, update it)
- Modify: `packages/gtk/.config/gtk-3.0/` and `gtk-4.0/`: create `gtk.css` with `@import url("file:///home/lugh/.cache/theme/gtk.css");`
- Modify: `packages/nvim/.config/nvim/lua/plugins/gruvbox.lua` -> becomes `theme.lua`: install gruvbox, catppuccin, everforest, nord plugins; `dofile(vim.fn.expand("~/.cache/theme/nvim.lua"))` when it exists, else gruvbox dark.
- Modify: `packages/btop/.config/btop/btop.conf` -> not includable; `theme-apply` edits the single `color_theme =` line in place (only that line). Verify the 5 btop theme names exist in `/usr/share/btop/themes/`; missing ones get a generated `.theme` in `~/.config/btop/themes/`.
- Modify: `packages/qt/.config/qt6ct/qt6ct.conf`: set `custom_palette=true`, `color_scheme_path=/home/lugh/.cache/theme/qt6ct.conf` (only those two keys).
- Deferred to after Task 9 (not in v1): yazi `theme.toml` and starship. Both already follow the terminal's ANSI colours, so they mostly recolour through foot.
- Create: `packages/quickshell/.config/quickshell/shell.qml`, `Theme.qml` (singleton, `FileView` on `~/.cache/theme/current.json`, `watchChanges: true`), `bar/Bar.qml`, `bar/Pill.qml`, `bar/Clock.qml`.

**Interfaces:**
- Produces: `Theme.bg0..purple`, `Theme.font`, `Theme.radius` (12), `Theme.pillHeight` (30); `Pill { property alias content; color: Theme.bg1 }`; `Bar` = `PanelWindow` per screen via `Variants { model: Quickshell.screens }`, anchors top/left/right, transparent, margins 8.

- [ ] **Step 1:** `theme-apply gruvbox-dark`; open a new foot, `swaymsg reload` -> borders and terminal unchanged from today (screenshot `grim` before/after, compare by eye).
- [ ] **Step 2:** `theme-apply gruvbox-light` -> new foot light, borders change, nvim opens light. Then `theme-apply --previous`.
- [ ] **Step 3:** Write skeleton; run `qs -p ~/.config/quickshell` beside Waybar -> bar with centred clock pill on both outputs, log has no `ERROR`.
- [ ] **Step 4:** `theme-apply nord` while `qs` runs -> clock pill recolours within 1 s without restart.
- [ ] **Step 5:** `swaymsg output HDMI-A-2 disable` then `enable` -> eDP-1 bar stays, HDMI bar returns.

### Task 3: Workspaces pill (Sway seam)

**Files:**
- Create: `compositor/Sway.qml` (singleton), `bar/Workspaces.qml`, `bar/icons.js`
- Test: `bar/icons_test.mjs` (`node --test`)

**Interfaces:**
- `Sway` (and any future `Hyprland.qml`) exposes: `property var workspaces` = list of `{ num:int, name:string, focused:bool, urgent:bool, appIds:[string] }`; `function focus(num)`.
- `icons.js`: `export function iconFor(appId, cls) -> string` (map ported verbatim from `workspace.jsonc`; `class<X>` keys match `cls`; fallback ``), `export function wsGlyph(ws) -> string`.

- [ ] **Step 1: Failing tests** in `icons_test.mjs`: `iconFor("firefox")=="󰈹"`, `iconFor("", "org.keepassxc.keepassxc")=="󰌾"`, `iconFor("unknown-app")==""`, `wsGlyph({focused:true})=="󰮯"`, `wsGlyph({urgent:true})=="󰧵"`, `wsGlyph({})=="󰊠"`.
- [ ] **Step 2:** `node --test bar/icons_test.mjs` -> FAIL.
- [ ] **Step 3:** Implement `icons.js` (`.pragma library`-compatible plain functions; QML imports it as JS). `Sway.qml`: workspace list from `Quickshell.I3` (`I3.workspaces`, `focusedWorkspace`, `dispatch("workspace number N")`); `appIds` from a `Process` running `swaymsg -t get_tree -r`, re-run on `I3` window/workspace events, walking `nodes` + `floating_nodes` for `app_id`/`window_properties.class`.
- [ ] **Step 4:** Tests PASS. Visual: focused ws = accent pill with `󰮯` + app icons, width animates (`Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }`); click switches workspace.

### Task 4: Left and right bar pills

**Files:** `bar/Logo.qml`, `bar/Launchers.qml`, `bar/Media.qml`, `bar/Volume.qml`, `bar/Network.qml`, `bar/Battery.qml`, `bar/ControlButton.qml`; modify `bar/Bar.qml` layout.

**Interfaces:** `Logo.clicked` -> `Panels.toggleLeft()`; `ControlButton.clicked` -> `Panels.toggleRight()` (defined in Task 5; stub until then).

- [ ] **Step 1:** Launchers run `footclient`, `footclient -e nvim`, `footclient -e yazi`, `obsidian`, `firefox` via `Quickshell.execDetached`.
- [ ] **Step 2:** Media: `Mpris.players` first playing player, `"artist — title"`, hidden when none; click play/pause.
- [ ] **Step 3:** Volume `Pipewire.defaultAudioSink` (`PwObjectTracker`), scroll changes 5 %. Battery `UPower.displayDevice`. Network: check `import Quickshell.Networking` loads on this build (`qs` log); if not, `nmcli -t -f ACTIVE,SSID dev wifi` polled every 10 s.
- [ ] **Step 4:** Visual check against the reference layout in the spec; pull `mpv` with audio to see the media pill.

### Task 5: Left panel (themes + wallpapers)

**Files:** `panels/Panels.qml` (singleton: `leftOpen`, `rightOpen`, `toggleLeft()`, `toggleRight()`, `IpcHandler { target: "panels" }`), `panels/LeftPanel.qml`.

- [ ] **Step 1:** `PanelWindow` on `Quickshell.screens` entry matching the focused Sway output, anchored top-left under the bar, `WlrLayershell.keyboardFocus: OnDemand`, closes on Escape / click outside.
- [ ] **Step 2:** Search field filtering `theme-apply --list` output; current theme marked; Enter/click runs `theme-apply <name>`.
- [ ] **Step 3:** Wallpaper grid of `~/Pictures/Wallpapers/*` thumbnails (`FolderListModel`); click -> `theme-apply --wallpaper <file>`; plus a "keep theme, only wallpaper" toggle that calls `~/.local/bin/wallpaper.sh <file>` instead.
- [ ] **Step 4:** Sway binds `bindsym $mod+t exec qs ipc call panels toggleLeft` (check `$mod+t` is free first).

### Task 6: Right panel (control center)

**Files:** `panels/RightPanel.qml`, `panels/Slider.qml`, `panels/Toggle.qml`.

- [ ] Toggles: wifi (`nmcli radio wifi on|off`), bluetooth (`bluetoothctl power on|off`), do-not-disturb (`Notifs.dnd`, Task 7). Sliders: volume (Pipewire), brightness (`brightnessctl set N%`, read `brightnessctl -m`). Media card (art, prev/play/next). Notification list from Task 7. Verify each control changes the real system.

### Task 7: Notifications (replace dunst)

**Files:** `notifications/Notifs.qml` (singleton `NotificationServer`, `tracked` list, `dnd`), `notifications/Popups.qml`.

- [ ] **Step 1:** Stop dunst (`pkill dunst`), start `qs`; `notify-send test hello` -> popup top-right, auto-dismiss 5 s, shows in right panel history. With `dnd` on, no popup but history entry.
- [ ] **Step 2:** `notify-send -u critical x y` stays until clicked.

### Task 8: Launcher (replace fuzzel)

**Files:** `launcher/Launcher.qml`; Sway bind replaces the fuzzel bind in `40-binds.conf` (edit only that line).

- [ ] Centred panel, search over `DesktopEntries.applications`, arrow keys + Enter launch, Escape closes. Verify launching foot, firefox, keepassxc.

### Task 9: Cut-over

**Files:** `packages/sway/.config/sway/config.d/50-autostart.conf` (replace the waybar line 57 with `exec qs`; remove `exec dunst`, `nm-applet`, `blueman-applet` lines; `exec_always theme-apply --previous` is NOT added, cache persists), `install.sh` + `packages/` (stow `quickshell`, `theme`; drop `waybar`, `dunst`, `fuzzel` packages; add `quickshell matugen brightnessctl` to the xbps list).

- [ ] **Step 1:** Show the user the exact diff; delete old packages only after their yes.
- [ ] **Step 2:** Log out and in (greetd) -> shell comes up alone, `pgrep -x waybar dunst nm-applet` empty.
- [ ] **Step 3:** Cycle all 5 themes and one wallpaper theme; every target recolours (open foot and running GTK apps on restart only, per spec).
