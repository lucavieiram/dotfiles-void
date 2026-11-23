import QtQuick
import Quickshell
import qs.components
import qs.services

// Void logo; opens the theme / wallpaper panel.
Pill {
    padding: 10
    color: Panels.leftOpen ? Theme.accent : Theme.bg1
    onClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleLeft(); }
    PText { text: ""; font.pixelSize: 15; color: Panels.leftOpen ? Theme.bg0 : Theme.accent }
}
