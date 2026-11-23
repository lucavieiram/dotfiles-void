//@ pragma UseQApplication
// Entry point: `qs` (or `qs -p <this folder>` to try it without installing).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import qs.panels
import qs.notifications
import qs.power
import qs.osd
import qs.lock
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    // Click anywhere outside an open panel closes it.
    PanelWindow {
        screen: Panels.screen ?? Compositor.focusedScreen
        visible: Panels.anyOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-scrim"
        MouseArea { anchors.fill: parent; onClicked: Panels.closeAll() }
    }

    LeftPanel {}
    RightPanel {}
    Popups {}
    PowerMenu {}
    CalendarPanel {}
    AudioPanel {}
    WifiPanel {}
    Osd {}
    Lock {}

    // Sway binds call these: qs ipc call panels toggleLeft
    IpcHandler {
        target: "panels"
        function toggleLeft(): void { Panels.screen = null; Panels.toggleLeft(); }
        function toggleRight(): void { Panels.screen = null; Panels.toggleRight(); }
        function toggleLauncher(): void { Panels.screen = null; Panels.left("apps", true); }
        function toggleThemes(): void { Panels.screen = null; Panels.left("themes", true); }
        function toggleWalls(): void { Panels.screen = null; Panels.left("walls", true); }
        function toggleClipboard(): void { Panels.screen = null; Panels.left("clip", true); }
        function togglePower(): void { Panels.screen = null; Panels.togglePower(); }
        function toggleAudio(): void { Panels.screen = null; Panels.toggleAudio(); }
        function toggleWifi(): void { Panels.screen = null; Panels.toggleWifi(); }
        function toggleCalendar(): void { Panels.screen = null; Panels.toggleCalendar(); }
        function closeAll(): void { Panels.closeAll(); }
    }
    // Make sure the notification daemon starts with the shell, not on first use.
    Component.onCompleted: Notifs.dnd
}
