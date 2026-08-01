#!/bin/bash
# disk-usage.sh — waybar: uso de / e /storage lado a lado.
#   (sem arg) → JSON pra waybar (barra mostra as duas % juntas; tooltip = detalhe)
#   --notify  → notificação com o detalhe separado (on-click)
set -u

ICON_ROOT="󱙋"
ICON_STORE="󰋊"
STORE_MNT="/storage"

# "pct used size" de um mountpoint (vazio se não montado)
read_disk() {
    df -h --output=pcent,used,size "$1" 2>/dev/null \
        | awk 'NR==2 { gsub(/%/,"",$1); print $1, $2, $3 }'
}

read -r RP RU RS < <(read_disk /)
read -r SP SU SS < <(read_disk "$STORE_MNT")
: "${RP:=?}" "${RU:=?}" "${RS:=?}"
if [ -z "${SP:-}" ]; then SP="—"; SU="—"; SS="—"; fi

# pior estado entre os dois discos → cor (class)
worst=0
for p in "$RP" "$SP"; do
    case "$p" in ''|*[!0-9]*) ;; *) [ "$p" -gt "$worst" ] && worst="$p" ;; esac
done
cls=""
[ "$worst" -ge 80 ] && cls="warning"
[ "$worst" -ge 90 ] && cls="critical"

# detalhe alinhado (tooltip + notificação)
detail=$(printf '%-9s %5s / %-5s %3s%%\n%-9s %5s / %-5s %3s%%' \
    "/" "$RU" "$RS" "$RP"  "$STORE_MNT" "$SU" "$SS" "$SP")

case "${1:-}" in
    --notify)
        notify-send -t 4000 -i drive-harddisk "Uso de disco" "$detail"
        ;;
    *)
        text="${ICON_ROOT} <span size='11pt'>${RP}%</span>  ${ICON_STORE} <span size='11pt'>${SP}%</span>"
        tt=${detail//$'\n'/\\n}   # escapa newlines pro JSON
        printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tt" "$cls"
        ;;
esac
