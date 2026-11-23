# Quickshell desktop shell -- design

Date: 2026-11-22. Machine: Void Linux, SwayFX 0.6 (sway 1.12), Qt 6.11.2, Quickshell 0.3.2 from the Void repo.

## Intent

Replace the current patchwork (Waybar + dunst + fuzzel + nm-applet + blueman-applet) with one
self-written Quickshell shell, so the desktop is unified, simpler, and recolourable as a whole.
Layout inspired by saneAspect's "fastest way to rice Hyprland with Quickshell" video
(youtube 7xx0MkKG0u4): floating pill bar, a square panel popping from the left (themes +
wallpapers), a square panel popping from the right (control center). His code is paid and
closed; nothing is copied from it.

## Goals

1. **Bar**: transparent strip, separate rounded pills.
   - Left: logo button (opens left panel), launcher buttons kept from current Waybar
     (terminal `footclient`, nvim, yazi, obsidian, firefox), now-playing pill (MPRIS).
   - Center: clock pill, workspaces pill.
   - Right: volume, network, battery pills, control-center button (opens right panel).
2. **Workspaces keep the current Waybar style** (`~/.config/waybar/modules/workspace.jsonc`):
   focused = Pac-Man glyph `󰮯` in an accent pill, others = ghost `󰊠`, urgent = red ghost
   `󰧵`, each followed by the icons of the apps open on it, using the same app-id -> glyph map
   (ported verbatim). Click switches workspace. Pill width animates on focus change.
3. **Left panel**: searchable list of themes; wallpaper grid from `~/Pictures/Wallpapers`;
   one extra entry "from wallpaper" (matugen). Picking applies system-wide.
4. **Right panel (control center)**: wifi / bluetooth / do-not-disturb toggles, volume and
   brightness sliders, media card, notification list.
5. **Notifications**: Quickshell is the notification daemon (popups + history in the right
   panel). dunst removed.
6. **Launcher**: Quickshell app launcher popup on a Sway keybind. fuzzel removed.
7. **System-wide theming (option 3 chosen)**: named palettes + matugen-from-wallpaper, both
   feeding one template step that writes every app's colours.
8. **Portable**: one default shell; compositor-specific code isolated in one file so a
   Hyprland/niri variant is "default + swap one file". If that split turns out large, drop it.

## Non-goals

- Login screen (greetd/tuigreet). Separate fix: greetd runs on `vt = 1` while
  `agetty-tty1` is also enabled; disable `agetty-tty1`. Quickshell greeter maybe later.
- Lock screen redesign (swaylock/gtklock stay; only recoloured).
- Hyprland/niri variants themselves -- only the seam for them.
- Copying saneAspect's paid code.

## Anti-goals (failure even if it works)

- More moving parts than today. Every replaced daemon must actually be removed from autostart.
- A config the user cannot read: no framework, no generated QML, small files, one per widget.
- Theme switch that leaves the desktop half-recoloured with no way back.

## Constraints

- Sway IPC via `Quickshell.I3` (workspaces, focus, dispatch). It does not document windows
  per workspace, so the app icons come from `swaymsg -t get_tree` (subscribed to window
  events), kept inside the Sway-specific file.
- Font: JetBrainsMono Nerd Font (already used).
- No systemd (runit + turnstile). Start the shell from Sway `exec`, like Waybar today
  (`sway/config.d/50-autostart.conf:57`).
- Licences: `tonybanters/quickshell-btw` has no licence -- read for ideas only, copy nothing.
  DankMaterialShell may be used for ideas; copy code only if its licence allows and keep
  attribution.
- Apps that cannot recolour live: open foot windows (use OSC 4/10/11 escape sequences to
  running ptys, as pywal does), running GTK/Qt apps (change on restart). Accept this.

## Approaches considered

1. Install DankMaterialShell and adapt -- fastest, but large foreign codebase, Material look,
   fights the pill layout and Pac-Man workspaces. Rejected: against "simpler" and "my layout".
2. **Own shell, borrowing ideas (chosen).** Small, readable, exact layout wanted.
Theming: (a) named palettes only, (b) matugen only, (c) **both (chosen)** -- named themes keep
control, wallpaper mode added as one more palette source.

## Shape of the how (decided)

```
~/.config/quickshell/
  shell.qml              entry: bar per monitor, panels, notification server
  Theme.qml              singleton, reads current palette JSON, live-reloads
  compositor/Sway.qml    workspaces + windows-per-workspace (the only Sway file)
  bar/ ...               one file per pill
  panels/LeftPanel.qml   themes + wallpapers
  panels/RightPanel.qml  control center
  launcher/, notifications/
~/.config/theme/
  palettes/<name>.json   ~16 named colours per theme (gruvbox, catppuccin, everforest, ...)
  templates/<app>.tmpl   one per target app
  apply                  script: palette -> render templates -> reload apps
```

`apply <name>` or `apply --wallpaper <file>` (matugen) writes `current.json`, renders
templates, sets wallpaper, reloads. Targets: Quickshell (live, file watch), Sway borders
(`swaymsg reload`), foot (ini + OSC to open ptys), GTK 3/4 (`gtk.css` colour overrides),
Qt (qt5ct/qt6ct colour scheme), nvim (colour file + signal running instances if simple),
btop, yazi, starship, swaylock/gtklock.

Source of truth for the config: `~/Code/dotfiles-void` (same as other dotfiles), linked or
installed into `~/.config` the way that repo already does it.

## Calls made after review (Claude's, correctable)

- **matugen** is in the Void repo (`matugen-4.2.0_1`); wallpaper mode is plannable.
- **Repo layout**: new stow package `packages/quickshell` (the shell) and `packages/theme`
  (palettes, templates, `apply`). Generated output is runtime state in `~/.cache/theme/`,
  never stowed, never in git.
- **Hand-written configs stay hand-owned.** Templates render only a colour fragment that each
  app includes: foot `include=`, sway `include`, GTK `@import` in `gtk.css`, nvim reads a
  colour file, etc. No app config is fully replaced, so stow symlinks are never overwritten.
- **Way back**: `apply` saves the previous palette name; `apply --previous` reverts. The
  default palette (gruvbox-material = today's colours) is git-tracked.
- **Compositor seam**: planned up front as one interface (`workspaces`, `focusWorkspace`,
  `windowsOn(ws)`) implemented by `compositor/Sway.qml`. Cheap now, expensive later.
- **Backends**: audio via `Quickshell.Services.Pipewire`; brightness via `brightnessctl`;
  MPRIS via `Quickshell.Services.Mpris`; notifications via
  `Quickshell.Services.Notifications`; network/bluetooth via the Quickshell modules if present
  in the 0.3.2 Void build, else `nmcli`/`bluetoothctl`. Verified at the first build step.
- **Power menu**: wlogout stays on its keybind; no power pill.
- **Monitors**: eDP-1 (laptop) + HDMI-A-2 (Acer KG241). Bar on both.

## Left to the builder

- Exact palette key names and the first set of themes (start: gruvbox-material = today's
  colours, everforest, catppuccin-mocha).
- Panel sizes, spacing, animation timings.
- Wallpaper setter (keep `swaybg`, matches current autostart).
- Which network/bluetooth backend: `Quickshell.Networking`/`Quickshell.Bluetooth` if they
  work on Void, else `nmcli`/`bluetoothctl` processes.
- Order of cut-over: run Quickshell beside Waybar until each replaced piece works, then
  remove Waybar/dunst/fuzzel/applets from autostart.
