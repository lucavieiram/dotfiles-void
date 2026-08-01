#!/usr/bin/env bash
# kb-layout-switch.sh — cycle keyboard layouts via swaymsg.
# Adapted from Hyprlust SwitchKeyboardLayout.sh (hyprctl → swaymsg).
#
# Bound to Super+K. Layouts are defined in sway/config.d/15-input.conf.

set -euo pipefail

command -v swaymsg >/dev/null || exit 1

# Identify any keyboard with a defined xkb_layout list
KB_ID=$(swaymsg -t get_inputs -r | \
    jq -r '.[] | select(.type=="keyboard" and (.xkb_layout_names|length > 0)) | .identifier' | head -1)

[ -n "$KB_ID" ] || { notify-send "KB Layout" "No keyboard with layout list found"; exit 1; }

# Cycle to next layout
swaymsg -- input "$KB_ID" xkb_switch_layout next >/dev/null

# Read back the new active layout name for the notification
active=$(swaymsg -t get_inputs -r | \
    jq -r --arg id "$KB_ID" '.[] | select(.identifier==$id) |
        .xkb_active_layout_name')

notify-send -t 1500 -i "input-keyboard" "Keyboard" "Layout: $active"
