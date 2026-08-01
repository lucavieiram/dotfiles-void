# Architecture

How dotfiles-void is structured and why.

## Two-layer install

| Layer  | Command            | Scope        | Privilege | Idempotent |
|--------|--------------------|--------------|-----------|------------|
| System | `./install.sh void`| `/`, services | sudo      | Bootstrap-only (run once) |
| GUI    | `./install.sh gui` | `$HOME`      | user      | Yes — safe to re-run after pulls |

System packages and drivers are installed once at the start of a machine's life. Dotfiles evolve continuously. Running `gui` doesn't need sudo and never touches `/`.

Both commands support `--dry-run` to preview xbps installs + sudo ops without running them.

## Phase scripts

Both installers iterate `installers/<layer>/phases/[0-9][0-9]-*.sh` in lexical order. The two-digit prefix lets new phases slot in without renumbering existing ones.

### System phases (`installers/system/phases/`)

| Phase | Purpose |
|-------|---------|
| `00-update`         | xbps self-update + base system update |
| `01-repos`          | Enable nonfree + multilib repos |
| `02-base`           | Core CLI tools (git, htop, btop, ImageMagick, cronie, …) |
| `03-gpu`            | NVIDIA driver + Mesa + GRUB kernel params |
| `04-session`        | seatd, elogind, dbus |
| `05-audio`          | PipeWire + WirePlumber + bluez + blueman |
| `06-fonts`          | JetBrainsMono Nerd, Inter, Noto, emoji |
| `07-wayland-stack`  | swayfx, Waybar, foot, fuzzel, dunst, gtklock, wlogout |
| `08-display-manager`| greetd + tuigreet |
| `09-shell-editor`   | zsh, neovim, lazygit, LSP toolchain deps |
| `10-devops`         | docker, wireguard, gpg |
| `11-security`       | AppArmor, nftables, sysctl hardening |
| `12-network`        | NetworkManager (DHCP DNS, captive-portal friendly); see `networking.md` |
| `13-gaming`         | Steam, Proton, gamemode, gamescope |
| `14-apps`           | KeePassXC, Nextcloud, Brave, Discord (Flatpak), Obsidian |
| `15-power`          | TLP |
| `16-user-groups`    | wheel, audio, video, input, … |
| `17-finalize`       | fc-cache, mandb, summary |
| `18-claude-code`    | Claude Code CLI via npm |

### GUI phases (`installers/gui/phases/`)

| Phase | Purpose |
|-------|---------|
| `00-stow`        | `stow` every package under `packages/` into `$HOME` |
| `01-zsh-plugins` | Clone zsh plugins (autosuggestions, syntax-highlighting) |
| `03-gsettings`   | Apply GTK theme + cursor + icon settings |
| `04-nvim-sync`   | Headless `nvim --headless +Lazy! sync +qa` |
| `05-wallpaper`   | Seed default wallpaper if `~/Pictures/Wallpapers/` is empty |

## Stow layout

`packages/<app>/` mirrors `$HOME`. For example, `packages/sway/.config/sway/config.d/` stows to `~/.config/sway/config.d/`. Each package is independently testable and reversible via `stow -D`.

The stow command is wrapped by `installers/lib/stow.sh` — phases don't call `stow` directly.

## Dry-run

`./install.sh --dry-run <cmd>` exports `DRY_RUN=1`. `installers/lib/log.sh` reads it and overrides the `sudo` function to print commands instead of executing them. `installers/lib/xbps.sh` does the same for `xbps_install`. Phases don't need to know about dry-run — it's transparent.

Caveat: only `sudo` and `xbps_install` are intercepted. Non-sudo file ops in `$HOME` still happen (gui phases create dirs, write configs).

## Why these choices

| Decision                           | Why |
|------------------------------------|-----|
| GNU Stow over custom symlink script| Industry-standard, declarative, easy to reverse |
| fuzzel over wofi/rofi              | Wayland-native, minimal, fast, supports icon protocol |
| foot over kitty/alacritty          | Wayland-native, tiny, signal reload, supports `include=` |
| swayfx over plain sway             | Native blur + corner_radius without managing a fork ourselves |
| swaybg over swww                   | One process, no daemon — wallpapers don't animate often |
| tuigreet over regreet (GTK)        | One less GTK runtime dependency on TTY1 |
| Modular Sway config                | Files split by concern — diffs are scoped, easier to reason about |
| Two-step install                   | Lower blast radius; `void` needs sudo, `gui` doesn't |
