import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

// Mic: click = mute/unmute (red when muted), scroll = mic volume, right-click = audio panel.
Pill {
    id: mic
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? false
    readonly property real vol: source?.audio?.volume ?? 0
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    visible: source !== null
    color: muted ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Theme.bg1
    onClicked: if (source?.audio) source.audio.muted = !muted
    onRightClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleAudio(); }
    onWheel: d => { if (source?.audio) source.audio.volume = Math.max(0, Math.min(1, vol + (d > 0 ? 0.05 : -0.05))); }
    PText { text: mic.muted ? "\u{f036d}" : "\u{f036c}"; color: mic.muted ? Theme.red : Theme.purple }
}
