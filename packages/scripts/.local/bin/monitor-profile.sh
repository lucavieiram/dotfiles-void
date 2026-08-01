#!/usr/bin/env bash
# monitor-profile.sh — quick switch between common monitor layouts.
# Bound to Super+Shift+M.
#
# Strategy: `swaymsg reload` first to restore both outputs to the canonical
# state declared in 10-outputs.conf (external at 0,0 + laptop at 1920,0,
# both enabled with their EDID-matched modes). Then layer per-profile
# tweaks on top (disable one, reposition).
#
# Why this and not the obvious `enable position …` per branch: re-enabling
# a previously `disable`d output is flaky on this NVIDIA setup — the kernel
# modesetting state gets stuck and the monitor stays black. A reload always
# brings outputs back from a clean slate. Cost: brief swaybg/wallpaper
# flicker as exec_always re-fires. Acceptable for an occasional layout swap.

INTERNAL="${INTERNAL_OUTPUT:-eDP-1}"
EXTERNAL="${EXTERNAL_OUTPUT:-HDMI-A-2}"

profiles="  Laptop only\n  Dual (laptop right)\n  Dual (laptop left)\n  External only"

choice=$(printf '%b' "$profiles" | fuzzel --dmenu --prompt 'Monitor: ' --lines 4 --width 40) || exit 0
[ -z "$choice" ] && exit 0

# Restore canonical both-on state from 10-outputs.conf
swaymsg reload

case "$choice" in
    *"Laptop only")
        swaymsg output "$EXTERNAL" disable
        ;;
    *"Dual (laptop right)")
        # Canonical default — nothing to change
        ;;
    *"Dual (laptop left)")
        swaymsg output "$INTERNAL" position 0,0
        swaymsg output "$EXTERNAL" position 1920,0
        ;;
    *"External only")
        swaymsg output "$INTERNAL" disable
        ;;
esac

notify-send -t 1500 -i "video-display" "Monitor" "${choice## }"
