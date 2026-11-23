import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

Pill {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    // click = audio panel (devices, mic, per-app); scroll = volume
    onClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleAudio(); }
    onWheel: d => { if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, vol + (d > 0 ? 0.05 : -0.05))); }
    PText { text: muted ? "\u{f075f}" : vol > 0.5 ? "\u{f057e}" : "\u{f0580}"; color: Theme.blue }
    PText { text: Math.round(vol * 100) + "%" }
}
