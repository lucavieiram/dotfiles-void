import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// shortcut: polls nmcli every 10 s; switch to Quickshell.Networking if its API settles.
Pill {
    id: net
    property string ssid: ""
    property int signal: 0
    Process {
        id: q
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.startsWith("yes:"));
                const f = line ? line.split(":") : [];
                net.ssid = f[1] ?? ""; net.signal = parseInt(f[2] ?? "0");
            }
        }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: q.running = true }
    onClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleWifi(); }
    PText { text: net.ssid ? "\u{f05a9}" : "\u{f05aa}"; color: Theme.purple }
    PText { text: net.ssid || "offline"; width: Math.min(implicitWidth, 140); elide: Text.ElideRight }
}
