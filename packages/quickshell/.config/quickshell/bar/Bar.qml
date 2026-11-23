import QtQuick
import Quickshell
import qs.services

// One per screen. Transparent strip; pills float on it.
PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.pillHeight + Theme.gap
    color: "transparent"
    margins { top: Theme.gap; left: Theme.gap; right: Theme.gap }

    Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 6
        Logo {}
        Launchers {}
        Media {}
    }
    Row {
        anchors.centerIn: parent
        spacing: 6
        Clock {}
        Workspaces {}
    }
    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 6
        Mic {}
        Volume {}
        Network {}
        Battery {}
        ControlButton {}
    }
}
