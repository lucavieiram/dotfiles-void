import QtQuick
import qs.services

// Rounded capsule; children go in a centred Row.
Rectangle {
    id: pill
    default property alias content: row.data
    property alias spacing: row.spacing
    property int padding: 12
    signal clicked()
    signal rightClicked()
    signal wheel(int delta)

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: area.containsMouse ? Theme.bg2 : Theme.bg1
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Row { id: row; anchors.centerIn: parent; spacing: 8 }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? pill.rightClicked() : pill.clicked()
        onWheel: w => pill.wheel(w.angleDelta.y)
    }
}
