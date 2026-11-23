import QtQuick
import qs.services

// 0..1 slider with a round icon badge (click badge = iconClicked, e.g. mute).
Item {
    id: s
    property real value: 0
    property string icon: ""
    property color tint: Theme.accent
    property bool dim: false
    signal moved(real value)
    signal iconClicked()
    implicitHeight: 36
    implicitWidth: 300

    IconCircle {
        id: ic; icon: s.icon; tint: s.dim ? Theme.fgDim : s.tint
        anchors.verticalCenter: parent.verticalCenter
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: s.iconClicked() }
    }
    Rectangle {
        id: track
        anchors { left: ic.right; leftMargin: 12; right: pct.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        height: 6; radius: 3; color: Theme.bg2
        Rectangle {
            width: track.width * Math.min(1, Math.max(0, s.value))
            height: parent.height; radius: 3; color: s.dim ? Theme.fgDim : s.tint
            Behavior on width { NumberAnimation { duration: 80 } }
        }
        MouseArea {
            anchors.fill: parent; anchors.topMargin: -12; anchors.bottomMargin: -12
            cursorShape: Qt.PointingHandCursor
            function set(x) { s.moved(Math.min(1, Math.max(0, x / track.width))); }
            onPressed: m => set(m.x)
            onPositionChanged: m => { if (pressed) set(m.x); }
        }
    }
    PText { id: pct; text: Math.round(s.value * 100) + "%"; width: 40; horizontalAlignment: Text.AlignRight
            font.pixelSize: 11; color: Theme.fgDim
            anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
}
