#!/usr/bin/env bash
# powermenu.sh — Lock / Logout / Reboot / Shutdown via wlogout.
set -euo pipefail
exec wlogout -b 2 --protocol layer-shell
