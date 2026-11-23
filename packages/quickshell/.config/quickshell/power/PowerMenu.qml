import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// Ctrl+Alt+Del: replaces wlogout. Same actions as packages/wlogout/layout, plus log out.
// Arrow keys + Enter, or click. Escape closes.
PanelWindow {
    id: w
    readonly property bool open: Panels.powerOpen
    screen: Panels.screen ?? Compositor.focusedScreen
    visible: open
    color: "transparent"
    implicitWidth: row.implicitWidth + 40
    implicitHeight: 170
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-power"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int current: 0
    onOpenChanged: current = 0
    readonly property var actions: [
        { label: "Lock",     icon: "\u{f033e}", tint: Theme.blue,   cmd: ["loginctl", "lock-session"] },
        { label: "Log out",  icon: "\u{f0343}", tint: Theme.yellow, cmd: ["swaymsg", "exit"] },
        { label: "Suspend",  icon: "\u{f04b2}", tint: Theme.purple, cmd: ["loginctl", "suspend"] },
        { label: "Reboot",   icon: "\u{f0709}", tint: Theme.orange, cmd: ["loginctl", "reboot"] },
        { label: "Shut down", icon: "\u{f0425}", tint: Theme.red,   cmd: ["loginctl", "poweroff"] }
    ]
    function run(i) { Panels.closeAll(); Quickshell.execDetached(actions[i].cmd); }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius + 6; color: Theme.bg0; border.color: Theme.bg2; border.width: 1
        focus: w.open
        Keys.onEscapePressed: Panels.closeAll()
        Keys.onLeftPressed: w.current = (w.current + w.actions.length - 1) % w.actions.length
        Keys.onRightPressed: w.current = (w.current + 1) % w.actions.length
        Keys.onReturnPressed: w.run(w.current)
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14
            Repeater {
                model: w.actions
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool sel: w.current === index || h.containsMouse
                    width: 110; height: 120; radius: Theme.radius
                    color: sel ? Theme.bg2 : Theme.bg1
                    border.width: sel ? 2 : 0; border.color: modelData.tint
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                    Column {
                        anchors.centerIn: parent; spacing: 10
                        IconCircle { icon: modelData.icon; tint: modelData.tint; filled: parent.parent.sel
                                     implicitWidth: 52; implicitHeight: 52; anchors.horizontalCenter: parent.horizontalCenter }
                        PText { text: modelData.label; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: w.current = index; onClicked: w.run(index) }
                }
            }
        }
    }
}
