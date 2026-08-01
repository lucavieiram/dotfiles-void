# Troubleshooting

Common issues and fixes.

## Sway will not start

- `sway -V` works but `sway` exits immediately → check `WLR_NO_HARDWARE_CURSORS=1` is set (NVIDIA workaround). Lives in `/etc/environment`.
- `(EE) Failed to read DRM_IOCTL_MODE_GETRESOURCES` → nouveau may be blocking. Verify `lsmod | grep nvidia` and that `modprobe.d` blacklists nouveau.
- Black screen after greetd: `sv status greetd` and `tail /var/log/socklog/greetd/current`.

## stow conflicts

Symptom: `./install.sh gui` fails with `WARNING! stowing X would cause conflicts`.

Fix: a file already exists at the target path. Either:

```sh
mv ~/.config/<file> ~/.config/<file>.bak
./install.sh gui
```

Or remove the conflicting package's old install: `stow -D <pkg>` from the previous source.

## NVIDIA flicker / black flashes

Graphical env vars live in `/etc/environment` (installed by `installers/system/phases/03-gpu.sh`), so they apply system-wide before any session starts. If you see flicker, verify the file contains:

```
WLR_NO_HARDWARE_CURSORS=1
__GL_GSYNC_ALLOWED=0
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=iHD          # Intel iGPU does video decode (Optimus default path)
GBM_BACKEND=nvidia-drm
```

> Note on `LIBVA_DRIVER_NAME`: keep `iHD` on Optimus laptops where the iGPU
> does video decode by default. Switching to `nvidia` requires installing
> the `nvidia-vaapi-driver` package; without it, VAAPI silently falls back
> to software decode and video playback pegs CPU.

Re-login (or reboot) after edits — `/etc/environment` is read by PAM at login.

## Waybar missing after boot

The autostart waits for the pipewire-pulse socket before launching waybar (see `packages/sway/.config/sway/config.d/50-autostart.conf`). If waybar still doesn't appear:

```sh
pgrep -x waybar                                  # should be present
pgrep -af waybar-ws-icons                        # orphan helper = waybar died
ls /run/user/$UID/pulse/native                   # socket present?
```

Start manually for debug:

```sh
waybar 2>&1 | head -40
```

## cliphist `Super+V` shows nothing

The clipboard watcher must be running. Verify in sway autostart:

```
exec wl-paste --type text  --watch cliphist store
exec wl-paste --type image --watch cliphist store
```

## Polkit prompts never appear

Verify the polkit agent is autostarting:

```sh
pgrep -fa lxqt-policykit-agent
```

If not, check `packages/sway/.config/sway/config.d/50-autostart.conf` and that `lxqt-policykit` is installed.

## DNS / wifi / captive portal

See [`networking.md`](networking.md) for the full architecture.

Quick triage:

```sh
nmcli general status                       # CONNECTIVITY=full means DNS+internet OK
cat /etc/resolv.conf                       # NM writes this from DHCP
getent hosts example.com                   # resolves?
nmcli device reapply <iface>               # if resolv.conf is empty after reconnect
wifi portal                                # force-open a captive-portal login URL
```

## Bluetooth (MT7922): "No default controller available"

Known bug — Mediatek BT firmware handshake fails with `Failed to send wmt func ctrl (-22)`. Fix shipped in mainline kernel via commit `162b1ad`; waiting for Void to ship kernel ≥ 6.18.33 or ≥ 7.0.9. See memory note `lesson_bluetooth_mt7922_wait` for full diagnostic and runtime workarounds that **do not** fix it (rfkill, module reload, USB unbind, `btusb.enable_autosuspend=0`).

## Reset everything

```sh
cd ~/dotfiles-void
for pkg in packages/*/; do
    stow -d packages -t ~ -D "$(basename "$pkg")"
done
```

This unstows every package. The repo itself is untouched.
