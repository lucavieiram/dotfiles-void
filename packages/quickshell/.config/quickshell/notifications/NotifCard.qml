import QtQuick
import qs.components
import qs.services

// One notification row: badge, summary, body, app name on the right. Click = dismiss.
Rectangle {
    id: card
    required property var notif
    readonly property bool critical: notif.urgency === 2   // NotificationUrgency.Critical
    width: parent?.width ?? 340
    implicitHeight: Math.max(56, col.implicitHeight + 20)
    radius: Theme.radius
    color: area.containsMouse ? Theme.bg2 : Theme.bg1

    IconCircle {
        id: badge
        anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 11 }
        icon: card.critical ? "\u{f0028}" : "\u{f009a}"
        tint: card.critical ? Theme.red : Theme.accent
    }
    Column {
        id: col
        anchors { left: badge.right; leftMargin: 10; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 10 }
        spacing: 2
        Item {
            width: parent.width; height: sum.implicitHeight
            PText { id: sum; text: card.notif.summary; font.bold: true; font.pixelSize: 12
                    width: parent.width - app.implicitWidth - 8; elide: Text.ElideRight }
            PText { id: app; text: card.notif.appName; anchors.right: parent.right; font.pixelSize: 10; color: Theme.fgDim }
        }
        PText { text: card.notif.body; visible: text !== ""; color: Theme.fgDim; font.pixelSize: 11
                width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                textFormat: Text.PlainText }
        Row {
            spacing: 6; topPadding: 4; visible: card.notif.actions.length > 0
            Repeater {
                model: card.notif.actions
                delegate: Pill {
                    required property var modelData
                    implicitHeight: 24; color: Theme.bg2
                    onClicked: modelData.invoke()
                    PText { text: modelData.text; font.pixelSize: 10 }
                }
            }
        }
    }
    MouseArea { id: area; anchors.fill: parent; z: -1; hoverEnabled: true; onClicked: card.notif.dismiss() }
}
