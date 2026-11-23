import QtQuick
import Quickshell.Services.Mpris
import qs.components
import qs.services

// "artist — title" of the playing player; click = play/pause. Hidden when nothing plays.
Pill {
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    visible: player !== null
    onClicked: player?.togglePlaying()
    PText { text: player?.isPlaying ? "\u{f03e4}" : "\u{f040a}"; color: Theme.accent }
    PText {
        width: Math.min(implicitWidth, 260); elide: Text.ElideRight
        text: player ? [player.trackArtist, player.trackTitle].filter(s => s).join(" — ") : ""
    }
}
