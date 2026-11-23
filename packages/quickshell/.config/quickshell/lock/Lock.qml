import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import qs.services

// Lock screen (replaces gtklock). ext-session-lock: if this process dies while locked,
// Sway keeps the screen locked, so a crash fails secure.
// Password checked by PAM with /etc/pam.d/gtklock (auth include login).
// Keys are read on every screen into one shared buffer; nothing is shown but dots.
Scope {
    id: root
    property bool locked: false
    property string buffer: ""        // typed password, cleared after every attempt
    property string error: ""
    property bool checking: false
    property int attempts: 0
    property string pamDir: "/etc/pam.d"   // tests point this at a pam_permit/pam_deny dir

    function lock() { if (!locked) { buffer = ""; error = ""; locked = true; } }
    function submit() {
        if (checking || buffer === "") return;
        checking = true; error = "";
        pam.start();
    }
    function key(e) {
        if (checking) return;
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) submit();
        else if (e.key === Qt.Key_Backspace) buffer = (e.modifiers & Qt.ControlModifier) ? "" : buffer.slice(0, -1);
        else if (e.key === Qt.Key_Escape) buffer = "";
        else if (e.text && e.text.charCodeAt(0) >= 32) buffer += e.text;
        error = "";
    }

    PamContext {
        id: pam
        config: "gtklock"
        configDirectory: root.pamDir
        user: Quickshell.env("USER")
        onResponseRequiredChanged: if (responseRequired) respond(root.buffer)
        onCompleted: result => {
            root.checking = false;
            root.buffer = "";
            if (result === PamResult.Success) { root.attempts = 0; root.locked = false; }
            else { root.attempts++; root.error = "Wrong password"; }
        }
        onError: err => { root.checking = false; root.buffer = ""; root.error = "Authentication error"; }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.locked; }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.bg0

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => { root.key(e); e.accepted = true; }

                // blurred, darkened wallpaper
                Image {
                    id: wall
                    anchors.fill: parent
                    source: "file://" + Theme.home + "/Pictures/Wallpapers/current.png"
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(surface.width / 2, surface.height / 2)
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    blurEnabled: true; blur: 1.0; blurMax: 64
                    brightness: Theme.dark ? -0.35 : -0.1
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -40
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, "HH:mm")
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 120; font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.date.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 20
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 120
                    spacing: 14

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                            Text { anchors.centerIn: parent; text: "\u{f0004}"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 16 }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Quickshell.env("USER")
                               color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
                    }

                    // password pill: dots only
                    Rectangle {
                        id: pill
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 340; height: 48; radius: 24
                        color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.85)
                        border.width: 2
                        border.color: root.error ? Theme.red : (root.checking ? Theme.yellow : Theme.accent)
                        Behavior on border.color { ColorAnimation { duration: Theme.anim } }

                        Text {
                            anchors.centerIn: parent
                            visible: root.buffer === ""
                            text: root.checking ? "Checking..." : (root.error || "Type your password")
                            color: root.error ? Theme.red : Theme.fgDim
                            font.family: Theme.font; font.pixelSize: 13
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Repeater {
                                model: Math.min(root.buffer.length, 24)
                                delegate: Rectangle { width: 10; height: 10; radius: 5; color: Theme.fg }
                            }
                        }
                        // shake on a wrong password
                        SequentialAnimation {
                            id: shake
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -8; duration: 60 }
                            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
                        }
                        Connections { target: root; function onAttemptsChanged() { if (root.attempts > 0) shake.restart(); } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.attempts >= 3
                        text: root.attempts + " failed attempts"
                        color: Theme.red; font.family: Theme.font; font.pixelSize: 11
                    }
                }

                // bottom: battery + hint
                Row {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 28 }
                    spacing: 18
                    Text {
                        readonly property var dev: UPower.displayDevice
                        visible: dev?.isLaptopBattery ?? false
                        text: "\u{f0079} " + Math.round(dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0) + "%"
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 12
                    }
                    Text { text: "Enter to unlock  ·  Esc clears"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
        }
    }
}
