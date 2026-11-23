import QtQuick
import qs.services

// Pill tile: icon badge + title + status line. Accent tint when on.
Rectangle {
    id: t
    property bool on: false
    property bool enabled: true
    property string icon: ""
    property string title: ""
    property string status: on ? "On" : "Off"
    property bool hasMore: false   // shows a › button on the right
    signal clicked()
    signal moreClicked()
    implicitHeight: 52
    radius: height / 2
    opacity: enabled ? 1 : 0.5
    color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (area.containsMouse ? Theme.bg2 : Theme.bg1)
    Behavior on color { ColorAnimation { duration: Theme.anim } }
    Row {
        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
        spacing: 10
        IconCircle { icon: t.icon; tint: t.on ? Theme.accent : Theme.fgDim; filled: t.on }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            PText { text: t.title; font.bold: true; font.pixelSize: 12 }
            PText { text: t.status; font.pixelSize: 10; color: Theme.fgDim; width: t.width - 70; elide: Text.ElideRight }
        }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; enabled: t.enabled
                cursorShape: Qt.PointingHandCursor; onClicked: t.clicked() }
    IconCircle {
        visible: t.hasMore
        icon: "\u{f0142}"; implicitWidth: 28; implicitHeight: 28; tint: Theme.fgDim
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.moreClicked() }
    }
}
