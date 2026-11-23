import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.notifications

// Control center: user row, 4 toggles, volume / mic / brightness, media card, notifications.
Popup {
    id: panel
    open: Panels.rightOpen
    anchors { top: true; right: true }
    margins.right: Theme.gap
    boxWidth: 390
    boxHeight: 900

    property string ssid: ""
    property bool wifiOn: true
    property bool btOn: false
    property bool nightOn: false
    property bool hasWlsunset: false
    property string uptime: ""
    // ProtonVPN = wg-quick tunnel /etc/wireguard/proton.conf (interface "proton").
    // Toggling needs the sudoers rule in installers/sudoers-wg-proton (no password prompt from a panel).
    property bool vpnOn: false
    // system stats, polled every 2 s only while the panel is open
    property var cpuPrev: null
    property real cpu: 0; property string cpuText: ""
    property real ram: 0; property string ramText: ""; property real ramTotal: 1
    property real gpu: 0; property string gpuText: ""
    property var disks: []   // [{ mount, used, size }] every real filesystem except /boot*
    property bool vpnAllowed: false
    property real brightness: 0
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

    // state is re-read every time the panel opens
    Process { running: panel.open; command: ["sh", "-c",
        "nmcli radio wifi; nmcli -t -f ACTIVE,SSID dev wifi list --rescan no | grep '^yes:' | cut -d: -f2;" +
        "echo; bluetoothctl show | grep -q 'Powered: yes' && echo bt-on || echo bt-off;" +
        "pgrep -x wlsunset >/dev/null && echo night-on || echo night-off;" +
        "command -v wlsunset >/dev/null && echo has-wlsunset || echo no-wlsunset;" +
        "cut -d. -f1 /proc/uptime; brightnessctl -m | cut -d, -f4;" +
        "ip link show proton >/dev/null 2>&1 && echo vpn-on || echo vpn-off;" +
        "sudo -k -n -l 2>/dev/null | grep -q 'NOPASSWD:.*wg-quick up proton' && echo vpn-allowed || echo vpn-denied"]
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n");
            panel.wifiOn = l[0] === "enabled";
            panel.ssid = l[1] ?? "";
            panel.btOn = text.includes("bt-on");
            panel.nightOn = text.includes("night-on");
            panel.hasWlsunset = text.includes("has-wlsunset");
            panel.vpnOn = text.includes("vpn-on");
            panel.vpnAllowed = text.includes("vpn-allowed");
            const up = parseInt(l.find(x => /^\d+$/.test(x)) ?? "0");
            panel.uptime = "up " + Math.floor(up / 3600) + "h " + Math.floor(up % 3600 / 60) + "m";
            const br = l.find(x => /^\d+%$/.test(x));
            if (br) panel.brightness = parseInt(br) / 100;
        } } }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14
        spacing: 12

        // user row
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            IconCircle { icon: "\u{f0004}"; implicitWidth: 40; implicitHeight: 40 }
            Column {
                Layout.fillWidth: true
                PText { text: Quickshell.env("USER"); font.bold: true }
                PText { text: panel.uptime; font.pixelSize: 11; color: Theme.fgDim }
            }
            IconCircle {
                icon: "\u{f0425}"; tint: Theme.red
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Panels.togglePower() }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2; columnSpacing: 8; rowSpacing: 8
            WideToggle {
                Layout.fillWidth: true; icon: "\u{f05a9}"; title: "Wi-Fi"; on: panel.wifiOn
                hasMore: true; onMoreClicked: Panels.toggleWifi()
                status: panel.wifiOn ? (panel.ssid || "not connected") : "Off"
                onClicked: { panel.wifiOn = !panel.wifiOn; panel.sh("nmcli radio wifi " + (panel.wifiOn ? "on" : "off")); }
            }
            WideToggle {
                Layout.fillWidth: true; icon: "\u{f00af}"; title: "Bluetooth"; on: panel.btOn
                onClicked: { panel.btOn = !panel.btOn; panel.sh("bluetoothctl power " + (panel.btOn ? "on" : "off")); }
            }
            WideToggle {
                Layout.fillWidth: true; icon: "\u{f0594}"; title: "Night Light"; on: panel.nightOn
                enabled: panel.hasWlsunset
                status: panel.hasWlsunset ? (panel.nightOn ? "On" : "Off") : "install wlsunset"
                // 4000 K all day: equal day/night temperatures, so no location is needed
                onClicked: { panel.nightOn = !panel.nightOn;
                             panel.sh(panel.nightOn ? "wlsunset -t 4000 -T 4001 -S 06:00 -s 18:00 >/dev/null 2>&1 &" : "pkill -x wlsunset"); }
            }
            WideToggle {
                Layout.fillWidth: true; icon: "\u{f009b}"; title: "Do not disturb"; on: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            WideToggle {
                Layout.fillWidth: true; Layout.columnSpan: 2
                icon: "\u{f0582}"; title: "ProtonVPN"
                on: panel.vpnOn
                enabled: panel.vpnAllowed
                status: !panel.vpnAllowed ? "needs the sudoers rule (see installers/sudoers-wg-proton)"
                      : panel.vpnOn ? "Connected (proton)" : "Off"
                onClicked: {
                    panel.vpnOn = !panel.vpnOn;
                    Quickshell.execDetached(["sudo", "-n", "wg-quick", panel.vpnOn ? "up" : "down", "proton"]);
                    vpnCheck.restart();
                }
            }
            Timer { id: vpnCheck; interval: 2500; onTriggered: vpnQ.running = true }   // confirm the real state
            Process { id: vpnQ; command: ["sh", "-c", "ip link show proton >/dev/null 2>&1"]
                      onExited: code => panel.vpnOn = code === 0 }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2; columnSpacing: 8; rowSpacing: 8
            StatCard { Layout.fillWidth: true; icon: "\u{f04bc}"; label: "CPU"; tint: Theme.green
                       value: panel.cpu; detail: panel.cpuText }
            StatCard { Layout.fillWidth: true; icon: "\u{f035b}"; label: "RAM"; tint: Theme.blue
                       value: panel.ram; detail: panel.ramText }
            StatCard { Layout.fillWidth: true; icon: "\u{f0379}"; label: "GPU"; tint: Theme.purple
                       value: panel.gpu; detail: panel.gpuText }
            Repeater {
                model: panel.disks
                delegate: StatCard {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    // an odd card at the end takes the full row
                    Layout.columnSpan: (index === panel.disks.length - 1 && (3 + panel.disks.length) % 2 === 1) ? 2 : 1
                    icon: "\u{f02ca}"; tint: Theme.yellow
                    label: modelData.mount === "/" ? "System" : modelData.mount.split("/").pop()
                    value: modelData.used / modelData.size
                    detail: (modelData.used / 1073741824).toFixed(0) + " / " + (modelData.size / 1073741824).toFixed(0) + " GB  " + modelData.mount
                }
            }
        }
        Process {
            id: statQ
            command: ["sh", "-c", "head -1 /proc/stat; echo cores $(nproc) $(cut -d' ' -f1 /proc/loadavg); grep -E '^(MemTotal|MemAvailable):' /proc/meminfo;" +
                "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | sed 's/^/gpu,/'"]
            stdout: StdioCollector { onStreamFinished: {
                const gb = b => (b / 1073741824).toFixed(1);
                for (const line of text.split("\n")) {
                    const f = line.trim().split(/[\s,]+/);
                    if (f[0] === "cpu") {
                        const v = f.slice(1).map(Number), idle = v[3] + v[4], total = v.reduce((a, b) => a + b, 0);
                        if (panel.cpuPrev) panel.cpu = 1 - (idle - panel.cpuPrev.idle) / Math.max(1, total - panel.cpuPrev.total);
                        panel.cpuPrev = { idle: idle, total: total };
                    } else if (f[0] === "cores") { panel.cpuText = f[1] + " threads  load " + f[2];
                    } else if (f[0] === "MemTotal:") { panel.ramTotal = Number(f[1]);
                    } else if (f[0] === "MemAvailable:") {
                        const used = panel.ramTotal - Number(f[1]);
                        panel.ram = used / panel.ramTotal;
                        panel.ramText = gb(used * 1024) + " / " + gb(panel.ramTotal * 1024) + " GB";
                    } else if (f[0] === "gpu") {
                        panel.gpu = Number(f[1]) / 100;
                        panel.gpuText = (Number(f[2]) / 1024).toFixed(1) + "/" + (Number(f[3]) / 1024).toFixed(1) + " GB  " + f[4] + "\u00b0C";
                    }
                }
            } }
        }
        // disk space barely moves: read once each time the panel opens, not every 2 s
        Process {
            command: ["df", "-B1", "--output=target,used,size", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
            running: panel.open
            stdout: StdioCollector { onStreamFinished: panel.disks = text.split("\n").slice(1)
                .map(l => l.trim().split(/\s+/)).filter(f => f.length === 3 && !f[0].startsWith("/boot"))
                .map(f => ({ mount: f[0], used: Number(f[1]), size: Number(f[2]) })) }
        }
        Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: panel.open
                onTriggered: statQ.running = true }

        Slider {
            Layout.fillWidth: true; tint: Theme.blue
            icon: panel.sink?.audio?.muted ? "\u{f075f}" : "\u{f057e}"
            dim: panel.sink?.audio?.muted ?? false
            value: panel.sink?.audio?.volume ?? 0
            onMoved: v => { if (panel.sink?.audio) panel.sink.audio.volume = v; }
            onIconClicked: if (panel.sink?.audio) panel.sink.audio.muted = !panel.sink.audio.muted
        }
        Slider {
            Layout.fillWidth: true; tint: Theme.purple
            icon: panel.source?.audio?.muted ? "\u{f036d}" : "\u{f036c}"
            dim: panel.source?.audio?.muted ?? false
            value: panel.source?.audio?.volume ?? 0
            onMoved: v => { if (panel.source?.audio) panel.source.audio.volume = v; }
            onIconClicked: if (panel.source?.audio) panel.source.audio.muted = !panel.source.audio.muted
        }
        Slider {
            Layout.fillWidth: true; tint: Theme.yellow
            icon: "\u{f00df}"
            value: panel.brightness
            onMoved: v => { panel.brightness = Math.max(0.02, v);
                            Quickshell.execDetached(["brightnessctl", "set", Math.round(panel.brightness * 100) + "%"]); }
        }

        // media card
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 72; radius: Theme.radius; color: Theme.bg1
            visible: panel.player !== null
            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 12
                Rectangle {
                    implicitWidth: 52; implicitHeight: 52; radius: 10; color: Theme.bg2; clip: true
                    Image { anchors.fill: parent; source: panel.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    PText { anchors.centerIn: parent; text: "\u{f075a}"; font.pixelSize: 22; color: Theme.fgDim
                            visible: !(panel.player?.trackArtUrl) }
                }
                Column {
                    Layout.fillWidth: true
                    PText { text: panel.player?.trackTitle ?? ""; font.bold: true; width: parent.width; elide: Text.ElideRight }
                    PText { text: panel.player?.trackArtist ?? ""; font.pixelSize: 11; color: Theme.fgDim
                            width: parent.width; elide: Text.ElideRight }
                }
                Repeater {
                    model: [
                        { icon: "\u{f04ae}", act: () => panel.player?.previous() },
                        { icon: "play", act: () => panel.player?.togglePlaying() },
                        { icon: "\u{f04ad}", act: () => panel.player?.next() }
                    ]
                    delegate: IconCircle {
                        required property var modelData
                        readonly property bool isPlay: modelData.icon === "play"
                        implicitWidth: 30; implicitHeight: 30
                        filled: isPlay
                        tint: isPlay ? Theme.accent : Theme.fgDim
                        icon: isPlay ? (panel.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}") : modelData.icon
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.act() }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            PText { text: "Notifications"; font.bold: true; Layout.fillWidth: true }
            PText {
                text: "Clear all"; color: Theme.accent; font.pixelSize: 11
                visible: Notifs.history.length > 0
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dismissAll() }
            }
        }
        ListView {
            id: hist
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 6
            model: Notifs.history.slice().reverse()
            delegate: NotifCard { required property var modelData; notif: modelData; width: hist.width }
            PText { anchors.centerIn: parent; visible: hist.count === 0; text: "nothing new"; color: Theme.fgDim }
        }
    }
}
