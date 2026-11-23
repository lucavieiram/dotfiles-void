import QtQuick
import Quickshell
import qs.components
import qs.services

// Same five buttons as waybar's distro group.
Pill {
    padding: 10
    spacing: 4
    Repeater {
        model: [
            { icon: "\u{f018d}", cmd: ["footclient"] },
            { icon: "",    cmd: ["footclient", "-e", "nvim"] },
            { icon: "\u{f0ab6}", cmd: ["footclient", "-e", "yazi"] },
            { icon: "\u{f082e}", cmd: ["obsidian"] },
            { icon: "\u{f0239}", cmd: ["firefox"] }
        ]
        delegate: Rectangle {
            required property var modelData
            width: 26; height: 24; radius: 8
            color: hov.containsMouse ? Theme.bg3 : "transparent"
            PText { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 15 }
            MouseArea {
                id: hov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(modelData.cmd)
            }
        }
    }
}
