import QtQuick
import Quickshell
import qs.components
import qs.services

Pill {
    padding: 10
    color: Panels.rightOpen ? Theme.accent : Theme.bg1
    onClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleRight(); }
    PText { text: "\u{f0493}"; font.pixelSize: 15; color: Panels.rightOpen ? Theme.bg0 : Theme.yellow }
}
