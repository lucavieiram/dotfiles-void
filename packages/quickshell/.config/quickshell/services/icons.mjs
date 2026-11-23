// Ported verbatim from waybar modules/workspace.jsonc (window-rewrite + format-icons).
// Plain ES module: imported by QML (import "icons.mjs" as Icons) and by node --test.
export const APP = {
  "firefox": "󰈹",
  "Firefox": "󰈹",
  "brave-browser": "󰊯",
  "brave": "󰊯",
  "Brave-browser": "󰊯",
  "foot": "󰆍",
  "footclient": "󰆍",
  "kitty": "󰆍",
  "alacritty": "󰆍",
  "code": "󰨞",
  "codium": "󰨞",
  "cursor": "󰨞",
  "nvim": "",
  "discord": "󰙯",
  "slack": "󰒱",
  "telegram-desktop": "",
  "spotify": "",
  "mpv": "󰕧",
  "imv": "󰋩",
  "zathura": "",
  "thunar": "󰪶",
  "yazi": "󰪶",
  "obsidian": "",
  "pavucontrol": "",
  "qt5ct": "",
  "qt6ct": "",
  "nm-connection-editor": "󰖩",
  "blueman-manager": "󰂯",
  "steam": "󰓓",
  "libreoffice-startcenter": "",
  "libreoffice-writer": "",
  "libreoffice-calc": "",
  "libreoffice-impress": "",
  "libreoffice-draw": "",
  "libreoffice-math": "",
  "libreoffice-base": ""
};
export const CLASS = {
  "com.brave.Browser": "󰊯",
  "org.keepassxc.keepassxc": "󰌾",
  "com.nextcloud.desktopclient.nextcloud": "󰕮"
};
export const GLYPH = {"focused": "󰮯", "default": "󰊠", "urgent": "󰧵", "empty": ""};
// waybar's default and several entries are empty strings there; empty falls back to this.
export const DEFAULT_APP = "\uf2d0";

export function iconFor(appId, cls) {
  return (cls && CLASS[cls]) || (appId && APP[appId]) || (cls && APP[cls]) || DEFAULT_APP;
}

export function wsGlyph(ws) {
  if (ws.urgent) return GLYPH.urgent;
  if (ws.focused) return GLYPH.focused;
  return GLYPH.default;
}
