# Acer Nitro V 15 (ANV15-51) – Controle de Fan + Power Profile

Setup que replica o NitroSense do Windows no Linux: controle manual de ventilador,
profiles térmicos, e gerenciamento automático baseado em AC/bateria/temperatura.

**Rodando hoje:** Void Linux (runit) + Sway, kernel série `6.18.x`.
Originalmente prototipado em CachyOS (`7.0.9-cachyos`) + Hyprland — daí algumas
referências a `paru`/`systemd` no histórico; abaixo está a versão Void.

> **Instalação canônica:** `installers/system/phases/15-power.sh` faz tudo isto
> de forma idempotente (módulo DKMS + serviço runit + scripts + sudoers). Este
> doc explica o *porquê* e serve de referência pra uso manual e troubleshooting.

---

## 1. Por que não basta o `acer-wmi` do kernel

O driver `acer-wmi` upstream:
- Detecta o Nitro V mas **não expõe** `pwm`, `fan_input` ou `thermal_profile`
- Só registra `platform_profile` com choices vazios (`Failed to register
  platform_profile class device with empty choices` no dmesg)
- Não suporta NitroSense v4 (modelos novos como o ANV15-51)

A solução é o **linuwu-sense** — fork não-oficial do `acer-wmi` com suporte
estendido pros Nitro/Predator modernos (repo: <https://github.com/0x7375646F/Linuwu-Sense>).

---

## 2. Por que DKMS (e não build manual) — leia isto

⚠️ **`linuwu-sense` é um módulo out-of-tree.** Se você compilar o `.ko` à mão
pra um kernel, ele **NÃO** é reconstruído nos updates seguintes — o módulo passa
a existir só pra aquele kernel antigo. No próximo `xbps-install -Su` que troca o
kernel, o autoload falha silenciosamente, o `acer_wmi` continua blacklistado
(sem fallback), e **todo o power profile morre**.

Foi exatamente o que aconteceu uma vez: o módulo estava buildado só pro
`6.18.32`, um update levou o sistema pro `6.18.36`, e ao trocar o boot no BIOS
pro SSD do Void (que bootava o kernel mais novo) os profiles sumiram. Diagnóstico
e correção: módulo só existia em `/lib/modules/6.18.32_1/...`, faltava pro kernel
em uso.

**Por isso instalamos via DKMS** — o DKMS recompila automaticamente em todo
update de kernel. Confirme que está registrado:

```bash
dkms status | grep linuwu
# linuwu-sense/1.0.0, 6.18.36_1, x86_64: installed
```

---

## 3. Instalação (Void)

### Via installer (recomendado)

```bash
./installers/system/phases/15-power.sh
```

### Manual (o que o installer faz, resumido)

```bash
# 1. Toolchain de build + DKMS
sudo xbps-install -y dkms gcc make git linux-headers

# 2. Fonte em /usr/src (commit fixado) + dkms.conf
sudo git clone https://github.com/0x7375646F/Linuwu-Sense.git /usr/src/linuwu-sense-1.0.0
# dkms.conf gerado pelo installer aponta BUILT_MODULE_NAME=linuwu_sense, src/

# 3. Build + install via DKMS
sudo dkms add    -m linuwu-sense -v 1.0.0
sudo dkms build  -m linuwu-sense -v 1.0.0
sudo dkms install -m linuwu-sense -v 1.0.0
```

### Configuração do módulo

Conflito conhecido: `acer-wmi` upstream e `linuwu-sense` brigam pela mesma WMI
interface. Solução é blacklistar o upstream + habilitar a flag `nitro_v4` (model
ANV15-51 e similares).

```bash
# /etc/modprobe.d/linuwu-sense.conf
blacklist acer_wmi
options linuwu_sense nitro_v4=1

# /etc/modules-load.d/linuwu-sense.conf  → autoload no boot
linuwu_sense
```

### Carregamento

```bash
sudo modprobe -r acer_wmi
sudo modprobe linuwu_sense nitro_v4=1
```

Confirma com:

```bash
lsmod | grep linuwu
ls /sys/devices/platform/acer-wmi/nitro_sense/
# → backlight_timeout battery_calibration battery_limiter boot_animation_sound
#   fan_speed lcd_override usb_charging
```

---

## 4. Controle manual

### Profile térmico

```bash
cat /sys/firmware/acpi/platform_profile_choices
# → low-power quiet balanced balanced-performance

echo balanced-performance | sudo tee /sys/firmware/acpi/platform_profile
```

`balanced-performance` é o mais alto disponível no ANV15-51 (não existe modo
"turbo" separado nesse hardware; turbo é fan-based).

### Fan (CPU,GPU)

Formato `CPU,GPU` em porcentagem 0–100. `0,0` = modo automático (kernel decide).

```bash
cat /sys/devices/platform/acer-wmi/nitro_sense/fan_speed   # ler
echo "100,100" | sudo tee /sys/devices/platform/acer-wmi/nitro_sense/fan_speed  # máximo
echo "0,0"     | sudo tee /sys/devices/platform/acer-wmi/nitro_sense/fan_speed  # auto
```

### Outros (expostos pelo linuwu-sense)

- `battery_limiter` — limita carga máxima (ex.: 80%) pra prolongar vida da bateria
- `usb_charging` — USB carrega aparelho com laptop desligado
- `backlight_timeout` — timeout do backlight do teclado
- `boot_animation_sound` — desliga o som de boot da Acer

---

## 5. Gerenciamento automático (Void / runit)

Dois scripts (versionados em `installers/system/assets/`):

- **`/usr/local/bin/acer-power-manager`** — daemon de decisão. Lê AC, bateria e
  temperatura (GPU via `nvidia-smi`, CPU via `coretemp`) e aplica profile + fan
  curve. Respeita um *override* manual em `/var/lib/acer-power/override`.
- **`/usr/local/bin/acer-profile-switcher`** — CLI que o waybar chama. Escreve o
  override e dispara o manager (via `sudo -n`).

### Lógica do manager

| Override      | Profile                | Fan      |
|---------------|------------------------|----------|
| `econ`        | `low-power`            | `0,0`    |
| `balanced`    | `balanced`             | `50,50`  |
| `performance` | `balanced-performance` | `80,80`  |
| `auto`/vazio  | temp-reativo (60/70/80 °C → curva crescente); bateria <45% sem AC → `low-power` |

### Serviço runit

`/etc/sv/acer-power/run` faz polling a cada 5s (pega mudança de bateria/temp):

```sh
#!/bin/sh
exec 2>&1
while :; do
    /usr/local/bin/acer-power-manager
    sleep 5
done
```

Log via `svlogd` em `/var/log/acer-power/`. Habilitar:

```bash
sudo ln -sf /etc/sv/acer-power /var/service/
```

### sudoers

O `acer-profile-switcher` roda como usuário mas precisa disparar o manager (que
escreve em `/sys`). Regra em `/etc/sudoers.d/acer-power`:

```
<user> ALL=(root) NOPASSWD: /usr/local/bin/acer-power-manager
```

### Waybar

Módulo `custom/power-profile` (em `packages/waybar/.config/waybar/modules/`)
chama `acer-profile-switcher --json`; clique cicla econ→balanced→performance.

### Diagnóstico

```bash
journalctl -t acer-power -n 20 --no-pager   # ou: tail /var/log/acer-power/current
sv status acer-power
cat /sys/firmware/acpi/platform_profile
cat /sys/devices/platform/acer-wmi/nitro_sense/fan_speed
sudo sv stop acer-power    # pausar auto-management
```

---

## 6. Troubleshooting

### Power profile parou depois de update de kernel / troca de boot

Quase sempre é o módulo DKMS **não registrado** (build manual antigo). Cheque:

```bash
dkms status | grep linuwu          # vazio = problema
lsmod | grep linuwu                # vazio = não carregou
ls /lib/modules/$(uname -r)/ -R | grep linuwu_sense   # existe pro kernel atual?
```

Se faltar pro kernel em uso, rode o installer (§3) — DKMS reconstrói. Ver §2.

### `modprobe: could not insert 'linuwu_sense': Input/output error`

Conflito com `acer_wmi` carregado. `sudo modprobe -r acer_wmi` e tenta de novo
(falta o blacklist do §3).

### Módulo carrega mas `/sys/devices/platform/linuwu_sense/` não existe

Esperado no ANV15-51 com `nitro_v4=1` — os controles ficam em
`/sys/devices/platform/acer-wmi/nitro_sense/` (o platform_device chama-se
`acer-wmi`, não `linuwu_sense`).

### `Platform profile registration failed (attempt 1/10), error: -22`

Normal no boot — tenta de novo, geralmente sucede na attempt 2. Passando de 10,
pode ser caso de BIOS update.

### Fan não responde ao `echo`

Escreva como root (`sudo tee`) e no formato `CPU,GPU` (vírgula, sem espaço).

---

## 7. Referências

- [linuwu-sense (GitHub)](https://github.com/0x7375646F/Linuwu-Sense) — fork
  ativo do acer-wmi com suporte v4
- `installers/system/phases/15-power.sh` — instalação canônica (DKMS + runit)
- `modinfo linuwu_sense` — flags disponíveis (nitro_v4, predator_v4, etc.)
- DMI do laptop: `cat /sys/class/dmi/id/product_name` → `Nitro ANV15-51`
