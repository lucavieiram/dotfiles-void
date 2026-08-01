# dotfiles-void

Personal Void Linux + Sway desktop. Two commands take a fresh Void install to a fully configured Wayland setup.

```sh
git clone https://github.com/<user>/dotfiles-void ~/dotfiles-void
cd ~/dotfiles-void
./install.sh --dry-run void   # preview what would happen
./install.sh void             # system layer  (xbps, drivers, services)  — uses sudo
sudo reboot
./install.sh gui              # graphical layer (dotfiles, plugins) — your user
```

## What's in the box

| Layer        | Tool                                 |
|--------------|--------------------------------------|
| Compositor   | swayfx (Sway fork with blur)         |
| Bar          | Waybar (gruvbox pill capsules)       |
| Terminal     | foot                                 |
| Launcher     | fuzzel                               |
| Notifications| dunst                                |
| Lock / idle  | gtklock + swayidle                   |
| Wallpaper    | swaybg                               |
| Power menu   | wlogout                              |
| Shell        | zsh + starship                       |
| Editor       | Neovim (LazyVim)                     |
| File manager | yazi                                 |
| Login        | greetd + tuigreet                    |

Everything is themed Gruvbox-dark.

## Highlights

- **Modular Sway config** — `packages/sway/.config/sway/config.d/*.conf` split by concern (env, input, output, binds, autostart)
- **Native waybar workspace icons** — `format-icons` per visible window (browser, editor, terminal glyphs auto-detected)
- **Dry-run installer** — `./install.sh --dry-run <cmd>` audits xbps + sudo ops before commit
- **Reversible dotfiles** — every package is `stow -D`-able

## Repository layout

```
dotfiles-void/
├── install.sh              ← entry point ({void|gui|help}, --dry-run)
├── installers/
│   ├── system/             ← `./install.sh void`
│   │   ├── install.sh
│   │   └── phases/         ← 00-update → 18-claude-code
│   ├── gui/                ← `./install.sh gui`
│   │   ├── install.sh
│   │   └── phases/         ← stow, zsh plugins, gsettings, nvim sync, wallpaper
│   └── lib/                ← log, colors, xbps, stow, grub helpers
├── packages/               ← GNU Stow units (one app per dir)
│   ├── sway/.config/sway/
│   ├── waybar/.config/waybar/
│   ├── wallpapers/Pictures/Wallpapers/
│   └── ... (24 packages)
└── docs/                   ← architecture, scripts, troubleshooting
```

## Requirements

- Working **Void Linux** base install (glibc)
- Network connectivity
- User in `wheel` group with sudo
- ~30 min for system install (mostly downloads)

## Daily-use keybinds

| Keybind            | Action                          |
|--------------------|---------------------------------|
| `Super+Return`     | Open foot terminal              |
| `Super+D`          | App launcher (fuzzel)           |
| `Super+V`          | Clipboard history               |
| `Super+/`          | Cheatsheet                      |
| `Super+Shift+W`    | Wallpaper picker                |
| `Super+Alt+←/→`    | Cycle wallpaper                 |
| `Super+P`          | Screenshot                      |
| `Super+L`          | Lock screen                     |
| `Ctrl+Alt+Del`     | Power menu (wlogout)            |

Full reference: `packages/sway/.config/sway/config.d/40-binds.conf`.

## Rollback

Every package is reversible via stow:

```sh
cd ~/dotfiles-void
stow -d packages -t ~ -D <pkg>   # unstow a single package
```

The `void` step is bootstrap-only — it doesn't keep modifying `/` over time.

## License

MIT — see `LICENSE`.
