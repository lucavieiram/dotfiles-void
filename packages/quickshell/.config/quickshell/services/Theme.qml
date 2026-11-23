pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Colours from ~/.cache/theme/current.json (written by theme-apply). Reloads live.
// Fallbacks are gruvbox-dark, so the bar still draws if the file is missing.
Singleton {
    id: root
    property var p: ({})

    readonly property string name: p.name ?? "gruvbox-dark"
    readonly property bool dark: (p.mode ?? "dark") === "dark"
    readonly property color bg0: p.bg0 ?? "#1d2021"
    readonly property color bg1: p.bg1 ?? "#282828"
    readonly property color bg2: p.bg2 ?? "#3c3836"
    readonly property color bg3: p.bg3 ?? "#504945"
    readonly property color fg: p.fg ?? "#ebdbb2"
    readonly property color fgDim: p.fg_dim ?? "#a89984"
    readonly property color accent: p.accent ?? "#478061"
    readonly property color red: p.red ?? "#cc241d"
    readonly property color orange: p.orange ?? "#d65d0e"
    readonly property color yellow: p.yellow ?? "#d79921"
    readonly property color green: p.green ?? "#98971a"
    readonly property color aqua: p.aqua ?? "#689d6a"
    readonly property color blue: p.blue ?? "#458588"
    readonly property color purple: p.purple ?? "#b16286"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int pillHeight: 30
    readonly property int gap: 8
    readonly property int radius: 14
    readonly property int anim: 200

    readonly property string home: Quickshell.env("HOME")
    readonly property string applyCmd: home + "/.local/bin/theme-apply"

    FileView {
        path: root.home + "/.cache/theme/current.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.p = JSON.parse(text()); } catch (e) { console.warn("theme: bad json", e); }
        }
    }
}
