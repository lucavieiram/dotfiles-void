#!/usr/bin/env bash
# hdmi-relink.sh — force a modeset on the external monitor after resume.
# After a suspend of hours with the lid closed, the KG241 on the NVIDIA HDMI
# port stays black until the lid opens; opening it re-enables eDP-1, and that
# full reconfigure is what wakes the monitor. Disable/enable reproduces it.
set -u
sleep 2
swaymsg 'output * power on' >/dev/null
swaymsg output HDMI-A-2 disable >/dev/null
swaymsg output HDMI-A-2 enable >/dev/null
