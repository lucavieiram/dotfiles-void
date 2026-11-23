import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Square panel under the bar on the focused screen. Escape closes.
PanelWindow {
    id: w
    property bool open: false
    default property alias content: box.data
    property int boxWidth: 380
    property int boxHeight: 560

    screen: Panels.screen ?? Compositor.focusedScreen
    visible: open || box.opacity > 0
    color: "transparent"
    implicitWidth: boxWidth
    implicitHeight: boxHeight + 16
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-popup"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal

    Rectangle {
        id: box
        width: w.boxWidth; height: w.boxHeight
        y: w.open ? 8 : -12
        opacity: w.open ? 1 : 0
        Behavior on y { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        radius: Theme.radius + 4
        color: Theme.bg0
        border.color: Theme.bg2; border.width: 1
        focus: w.open
        Keys.onEscapePressed: Panels.closeAll()
    }
}
