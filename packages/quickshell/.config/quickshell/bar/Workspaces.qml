import QtQuick
import qs.components
import qs.services

// Pac-Man on the focused workspace, ghosts on the rest, app icons after each.
Pill {
    padding: 4
    spacing: 4
    Repeater {
        model: Compositor.workspaces
        delegate: Rectangle {
            required property var modelData
            readonly property bool active: modelData.focused
            height: Theme.pillHeight - 8
            width: label.implicitWidth + (active ? 24 : 14)
            radius: height / 2
            color: active ? Theme.accent : (hov.containsMouse ? Theme.bg3 : "transparent")
            Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            PText {
                id: label
                anchors.centerIn: parent
                text: [modelData.glyph].concat(modelData.icons).join("  ")
                color: modelData.urgent ? Theme.red : (parent.active ? Theme.bg0 : Theme.fgDim)
            }
            MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Compositor.focus(modelData.num) }
        }
    }
}
