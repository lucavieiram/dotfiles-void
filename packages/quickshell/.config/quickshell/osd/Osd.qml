import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.components
import qs.services

// Small bar at the bottom when volume, mic mute or brightness change.
// Volume reacts to PipeWire by itself; brightness is pushed by the key binds (qs ipc call osd brightness).
PanelWindow {
    id: osd
    property string icon: ""
    property real value: 0
    property color tint: Theme.blue
    property bool shown: false

    screen: Compositor.focusedScreen
    visible: shown || box.opacity > 0
    anchors.bottom: true
    margins.bottom: 60
    implicitWidth: 320; implicitHeight: 56
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"

    function show(icon, value, tint) {
        if (Panels.rightOpen) return;          // the control center already shows it
        osd.icon = icon; osd.value = value; osd.tint = tint; osd.shown = true; hide.restart();
    }
    Timer { id: hide; interval: 1400; onTriggered: osd.shown = false }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    property bool ready: false
    Timer { interval: 1500; running: true; onTriggered: osd.ready = true }   // ignore the initial values at startup
    Connections {
        target: osd.sink?.audio ?? null
        function onVolumeChanged() { if (osd.ready) osd.showVolume(); }
        function onMutedChanged() { if (osd.ready) osd.showVolume(); }
    }
    function showVolume() {
        const a = sink.audio;
        show(a.muted ? "\u{f075f}" : "\u{f057e}", a.muted ? 0 : a.volume, Theme.blue);
    }

    Process {
        id: br
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: osd.show("\u{f00df}", parseInt(text.split(",")[3] ?? "0") / 100, Theme.yellow) }
    }
    IpcHandler {
        target: "osd"
        function brightness(): void { br.running = true; }
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: height / 2; color: Theme.bg0; border.color: Theme.bg2; border.width: 1
        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        Slider {
            anchors { fill: parent; leftMargin: 11; rightMargin: 16 }
            icon: osd.icon; tint: osd.tint; value: osd.value
            enabled: false
        }
    }
}
