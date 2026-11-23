import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Toasts, top-right of the focused screen.
PanelWindow {
    screen: Compositor.focusedScreen
    visible: Notifs.popups.length > 0
    anchors { top: true; right: true }
    margins { top: 8; right: 8 }
    implicitWidth: 360
    implicitHeight: col.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    Column {
        id: col
        width: parent.width
        spacing: 8
        Repeater {
            model: Notifs.popups
            delegate: NotifCard { required property var modelData; notif: modelData.n; width: col.width }
        }
    }
}
