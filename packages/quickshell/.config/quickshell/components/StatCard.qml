import QtQuick
import qs.services

// Read-only meter: badge, label, value text, thin bar (0..1).
Rectangle {
    id: c
    property string icon: ""
    property string label: ""
    property string detail: ""
    property real value: 0
    property color tint: Theme.accent
    implicitHeight: 62
    radius: Theme.radius
    color: Theme.bg1
    readonly property color barColor: value > 0.9 ? Theme.red : value > 0.75 ? Theme.orange : tint

    IconCircle { id: b; icon: c.icon; tint: c.barColor; implicitWidth: 30; implicitHeight: 30
                 anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 9 } }
    Column {
        anchors { left: b.right; leftMargin: 8; right: parent.right; rightMargin: 10; top: parent.top; topMargin: 8 }
        PText { text: c.label + "  " + Math.round(c.value * 100) + "%"; font.bold: true; font.pixelSize: 11 }
        PText { text: c.detail; font.pixelSize: 9; color: Theme.fgDim; width: parent.width; elide: Text.ElideRight }
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
        height: 4; radius: 2; color: Theme.bg2
        Rectangle { width: parent.width * Math.min(1, c.value); height: parent.height; radius: 2; color: c.barColor
                    Behavior on width { NumberAnimation { duration: 300 } } }
    }
}
