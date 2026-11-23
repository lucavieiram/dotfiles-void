import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// Opened from the wifi pill or the Wi-Fi tile arrow. Everything goes through nmcli.
// Click a network to open it: connect / disconnect / forget / auto-connect, plus details when connected.
Popup {
    id: panel
    open: Panels.wifiOpen
    anchors { top: true; right: true }
    margins.right: Theme.gap
    boxWidth: 400
    boxHeight: 640

    property bool radioOn: true
    property string device: ""     // wifi interface, e.g. wlp63s0
    property var networks: []      // [{ ssid, signal, secure, security, active, known, freq, rate, chan }]
    property var known: []         // saved wireless connection names
    property var details: ({})     // connected network: ip, gateway, dns, mac
    property var autoconnect: ({}) // ssid -> bool, filled when a known network is opened
    property string expanded: ""   // ssid whose options are open
    property bool asking: false    // password field shown for `expanded`
    property bool confirmForget: false
    property string status: ""
    property bool busy: false

    function refresh() { if (!scan.running) scan.running = true; }
    onOpenChanged: if (open) { expanded = ""; asking = false; status = "";
                               Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]); refresh(); }

    // nmcli -t escapes ':' and '\' inside values; split on unescaped ':' only
    function fields(line) {
        const out = []; let cur = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
            if (line[i] === ":") { out.push(cur); cur = ""; continue; }
            cur += line[i];
        }
        out.push(cur);
        return out;
    }

    Process {
        id: scan
        command: ["sh", "-c",
            "nmcli radio wifi; echo ---; nmcli -t -f NAME,TYPE connection show; echo ---;" +
            "nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,RATE,CHAN,SSID dev wifi list --rescan no; echo ---;" +
            "d=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -1); echo \"$d\"; echo ---;" +
            "[ -n \"$d\" ] && nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR dev show \"$d\""]
        stdout: StdioCollector { onStreamFinished: {
            const parts = text.split("---\n");
            panel.radioOn = parts[0].trim() === "enabled";
            panel.known = (parts[1] ?? "").split("\n").map(l => panel.fields(l))
                .filter(f => f[1] === "802-11-wireless").map(f => f[0]);
            const seen = {};
            for (const l of (parts[2] ?? "").split("\n")) {
                if (!l) continue;
                const f = panel.fields(l), ssid = f[6];
                if (!ssid) continue;
                const n = { ssid: ssid, signal: parseInt(f[1]) || 0, security: f[2], secure: f[2] !== "" && f[2] !== "--",
                            freq: f[3], rate: f[4], chan: f[5], active: f[0] === "*", known: panel.known.includes(ssid) };
                if (!seen[ssid] || n.active || n.signal > seen[ssid].signal) seen[ssid] = n;
            }
            panel.networks = Object.values(seen).sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal));
            panel.device = (parts[3] ?? "").trim();
            const d = {};
            for (const l of (parts[4] ?? "").split("\n")) {
                const i = l.indexOf(":"); if (i < 0) continue;
                const k = l.slice(0, i), v = l.slice(i + 1);
                if (k.startsWith("IP4.ADDRESS")) d.ip = d.ip ?? v;
                else if (k === "IP4.GATEWAY") d.gateway = v;
                else if (k.startsWith("IP4.DNS")) d.dns = (d.dns ? d.dns + ", " : "") + v;
                else if (k === "GENERAL.HWADDR") d.mac = v;
            }
            panel.details = d;
        } }
    }
    Timer { interval: 5000; repeat: true; running: panel.open && !panel.busy && !panel.asking; onTriggered: panel.refresh() }

    // auto-connect flag of a saved network
    Process {
        id: acQ
        property string ssid: ""
        stdout: StdioCollector { onStreamFinished: {
            const a = Object.assign({}, panel.autoconnect);
            a[acQ.ssid] = text.trim() === "yes";
            panel.autoconnect = a;
        } }
    }
    function readAutoconnect(ssid) {
        if (acQ.running) return;
        acQ.ssid = ssid;
        acQ.command = ["nmcli", "-g", "connection.autoconnect", "connection", "show", "id", ssid];
        acQ.running = true;
    }

    // one action at a time; result goes to the status line
    Process {
        id: act
        property string what: ""
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: code => {
            panel.busy = false;
            panel.status = code === 0 ? act.what + ": done" : (actErr.text || actOut.text).trim().split("\n").pop();
            if (code === 0) { panel.asking = false; panel.confirmForget = false; }
            panel.refresh();
        }
    }
    function run(what, cmd) { if (act.running) return; act.what = what; act.command = cmd; busy = true; status = what + "..."; act.running = true; }

    function toggle(n) {
        confirmForget = false; asking = false;
        expanded = expanded === n.ssid ? "" : n.ssid;
        if (expanded && n.known) readAutoconnect(n.ssid);
    }
    function connect(n) {
        if (n.known) run("Connect", ["nmcli", "connection", "up", "id", n.ssid]);
        else if (!n.secure) run("Connect", ["nmcli", "device", "wifi", "connect", n.ssid]);
        else asking = true;
    }
    // shortcut: the password is passed as an nmcli argument, so it is briefly visible in `ps`.
    function connectWith(ssid, pw) { run("Connect", ["nmcli", "device", "wifi", "connect", ssid, "password", pw]); }
    function disconnect(n) { run("Disconnect", ["nmcli", "connection", "down", "id", n.ssid]); }
    function forget(n) {
        if (!confirmForget) { confirmForget = true; return; }   // second click confirms
        expanded = "";
        run("Forget " + n.ssid, ["nmcli", "connection", "delete", "id", n.ssid]);
    }
    function setAutoconnect(n, on) {
        const a = Object.assign({}, autoconnect); a[n.ssid] = on; autoconnect = a;
        run("Auto-connect " + (on ? "on" : "off"), ["nmcli", "connection", "modify", "id", n.ssid, "connection.autoconnect", on ? "yes" : "no"]);
    }

    component Switch: Rectangle {
        property bool on: false
        signal toggled()
        implicitWidth: 40; implicitHeight: 22; radius: 11
        color: on ? Theme.accent : Theme.bg3
        Rectangle { width: 16; height: 16; radius: 8; y: 3; color: Theme.bg0; x: parent.on ? 21 : 3
                    Behavior on x { NumberAnimation { duration: Theme.anim } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.toggled() }
    }
    component Action: Pill {
        property alias label: lbl.text
        property color tint: Theme.fg
        implicitHeight: 28
        color: Theme.bg2
        PText { id: lbl; font.pixelSize: 11; color: parent.parent.tint }
    }
    component Info: RowLayout {
        property alias key: k.text
        property alias value: v.text
        Layout.fillWidth: true; visible: v.text !== ""
        PText { id: k; font.pixelSize: 10; color: Theme.fgDim; Layout.preferredWidth: 76 }
        PText { id: v; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            PText { text: "Wi-Fi"; font.bold: true; font.pixelSize: 15 }
            PText { text: panel.device; font.pixelSize: 10; color: Theme.fgDim; Layout.fillWidth: true; Layout.leftMargin: 6 }
            Switch {
                on: panel.radioOn
                onToggled: { panel.radioOn = !panel.radioOn;
                             Quickshell.execDetached(["nmcli", "radio", "wifi", panel.radioOn ? "on" : "off"]);
                             refreshLater.restart(); }
            }
            Timer { id: refreshLater; interval: 2500; onTriggered: panel.refresh() }
        }
        PText { text: panel.status; visible: text !== ""; font.pixelSize: 11; color: Theme.fgDim
                Layout.fillWidth: true; elide: Text.ElideRight }

        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 6
            model: panel.radioOn ? panel.networks : []
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var n: modelData
                readonly property bool open: panel.expanded === n.ssid
                width: list.width; radius: 22
                height: open ? 46 + body.implicitHeight + 12 : 46
                clip: true
                color: n.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                       : (open || h.containsMouse ? Theme.bg2 : Theme.bg1)
                Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

                // header
                RowLayout {
                    x: 7; y: 6; width: parent.width - 18; spacing: 10
                    IconCircle {
                        filled: row.n.active
                        icon: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"][Math.min(4, Math.floor(row.n.signal / 20))]
                    }
                    Column {
                        Layout.fillWidth: true
                        PText { text: row.n.ssid; font.bold: true; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight }
                        PText { font.pixelSize: 10; color: Theme.fgDim
                                text: (row.n.active ? "Connected  " : row.n.known ? "Saved  " : "") + row.n.signal + "%" }
                    }
                    PText { text: row.n.secure ? "\u{f033e}" : ""; color: Theme.fgDim }
                    PText { text: row.open ? "\u{f0143}" : "\u{f0140}"; color: Theme.fgDim }
                }
                MouseArea { id: h; width: parent.width; height: 46; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: panel.toggle(row.n) }

                // options
                ColumnLayout {
                    id: body
                    visible: row.open
                    x: 14; y: 50; width: parent.width - 28
                    spacing: 6

                    Info { key: "Security"; value: row.n.security || "open" }
                    Info { key: "Band"; value: row.n.freq ? row.n.freq + "  ch " + row.n.chan : "" }
                    Info { key: "Speed"; value: row.n.active ? row.n.rate : "" }
                    Info { key: "IP"; value: row.n.active ? (panel.details.ip ?? "") : "" }
                    Info { key: "Gateway"; value: row.n.active ? (panel.details.gateway ?? "") : "" }
                    Info { key: "DNS"; value: row.n.active ? (panel.details.dns ?? "") : "" }
                    Info { key: "MAC"; value: row.n.active ? (panel.details.mac ?? "") : "" }

                    RowLayout {
                        visible: row.n.known
                        Layout.fillWidth: true; Layout.topMargin: 2
                        PText { text: "Connect automatically"; font.pixelSize: 11; Layout.fillWidth: true }
                        Switch { on: panel.autoconnect[row.n.ssid] ?? true; onToggled: panel.setAutoconnect(row.n, !on) }
                    }

                    // password for a new secured network
                    Rectangle {
                        visible: panel.asking && row.open
                        Layout.fillWidth: true; implicitHeight: 34; radius: 17; color: Theme.bg0
                        TextInput {
                            id: pw
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 12
                            focus: panel.asking && row.open
                            PText { text: "Password, then Enter"; color: Theme.fgDim; font.pixelSize: 11
                                    visible: !pw.text; anchors.verticalCenter: parent.verticalCenter }
                            Keys.onReturnPressed: if (text.length > 0) panel.connectWith(row.n.ssid, text)
                            Keys.onEscapePressed: { panel.asking = false; text = ""; }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 2; spacing: 6
                        Action {
                            label: row.n.active ? "Disconnect" : "Connect"
                            tint: row.n.active ? Theme.fg : Theme.accent
                            onClicked: row.n.active ? panel.disconnect(row.n) : panel.connect(row.n)
                        }
                        Action {
                            visible: row.n.known
                            label: panel.confirmForget ? "Sure? Forget" : "Forget"
                            tint: Theme.red
                            onClicked: panel.forget(row.n)
                        }
                        Item { Layout.fillWidth: true }
                        Action {
                            visible: row.n.known
                            label: "Edit"
                            onClicked: { Panels.closeAll(); Quickshell.execDetached(["nm-connection-editor"]); }
                        }
                    }
                }
            }
            PText { anchors.centerIn: parent; visible: list.count === 0; color: Theme.fgDim
                    text: panel.radioOn ? "Scanning..." : "Wi-Fi is off" }
        }

        Pill {
            Layout.alignment: Qt.AlignRight
            onClicked: { Panels.closeAll(); Quickshell.execDetached(["nm-connection-editor"]); }
            PText { text: "\u{f0493}  Network settings"; font.pixelSize: 11 }
        }
    }
}
