import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

// Opened from the volume pill: output + input volume and device pickers, per-app volume.
Popup {
    id: panel
    open: Panels.audioOpen
    anchors { top: true; right: true }
    margins.right: Theme.gap
    boxWidth: 400
    boxHeight: 620

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.isStream && !n.isSink)   // playback streams
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: panel.nodes }

    function label(n) { return n.nickname || n.description || n.name; }

    component Section: PText { font.bold: true; Layout.topMargin: 4 }
    // one selectable device row
    component DeviceRow: Rectangle {
        required property var node
        required property bool current
        signal picked()
        Layout.fillWidth: true; implicitHeight: 34; radius: height / 2
        color: current ? Theme.bg2 : (h.containsMouse ? Theme.bg1 : "transparent")
        Row {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 8
            PText { text: parent.parent.current ? "\u{f0133}" : "\u{f0130}"; color: parent.parent.current ? Theme.accent : Theme.fgDim }
            PText { text: panel.label(parent.parent.node); font.pixelSize: 12; width: 300; elide: Text.ElideRight }
        }
        MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.picked() }
    }

    Flickable {
        anchors.fill: parent; anchors.margins: 14
        contentHeight: col.implicitHeight
        clip: true
        ColumnLayout {
            id: col
            width: parent.width
            spacing: 8

            Section { text: "Output" }
            Slider {
                Layout.fillWidth: true; tint: Theme.blue
                icon: panel.sink?.audio?.muted ? "\u{f075f}" : "\u{f057e}"
                dim: panel.sink?.audio?.muted ?? false
                value: panel.sink?.audio?.volume ?? 0
                onMoved: v => { if (panel.sink?.audio) panel.sink.audio.volume = v; }
                onIconClicked: if (panel.sink?.audio) panel.sink.audio.muted = !panel.sink.audio.muted
            }
            Repeater {
                model: panel.sinks
                delegate: DeviceRow {
                    required property var modelData
                    node: modelData; current: modelData === panel.sink
                    onPicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            Section { text: "Microphone" }
            Slider {
                Layout.fillWidth: true; tint: Theme.purple
                icon: panel.source?.audio?.muted ? "\u{f036d}" : "\u{f036c}"
                dim: panel.source?.audio?.muted ?? false
                value: panel.source?.audio?.volume ?? 0
                onMoved: v => { if (panel.source?.audio) panel.source.audio.volume = v; }
                onIconClicked: if (panel.source?.audio) panel.source.audio.muted = !panel.source.audio.muted
            }
            Repeater {
                model: panel.sources
                delegate: DeviceRow {
                    required property var modelData
                    node: modelData; current: modelData === panel.source
                    onPicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            Section { text: "Apps"; visible: panel.apps.length > 0 }
            Repeater {
                model: panel.apps
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 0
                    PText { text: modelData.properties["application.name"] ?? panel.label(modelData)
                            font.pixelSize: 11; color: Theme.fgDim; Layout.leftMargin: 46 }
                    Slider {
                        Layout.fillWidth: true; tint: Theme.aqua
                        icon: modelData.audio.muted ? "\u{f075f}" : "\u{f0388}"
                        dim: modelData.audio.muted
                        value: modelData.audio.volume
                        onMoved: v => modelData.audio.volume = v
                        onIconClicked: modelData.audio.muted = !modelData.audio.muted
                    }
                }
            }

            Pill {
                Layout.alignment: Qt.AlignRight; Layout.topMargin: 6
                onClicked: { Panels.closeAll(); Quickshell.execDetached(["pavucontrol"]); }
                PText { text: "\u{f0493}  Advanced (pavucontrol)"; font.pixelSize: 11 }
            }
        }
    }
}
