import QtQuick
import qs.services

// Round icon badge used in tiles, sliders and notification rows.
Rectangle {
    property alias icon: t.text
    property color tint: Theme.accent
    property bool filled: false
    implicitWidth: 34; implicitHeight: 34
    radius: width / 2
    color: filled ? tint : Qt.rgba(tint.r, tint.g, tint.b, 0.18)
    PText { id: t; anchors.centerIn: parent; font.pixelSize: 15; color: parent.filled ? Theme.bg0 : parent.tint }
}
