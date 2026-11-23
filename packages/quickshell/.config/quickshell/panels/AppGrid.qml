import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

// Apps tab with no search text: Recent, Most used, then one group per freedesktop category.
Flickable {
    id: view
    signal launched()
    contentHeight: col.implicitHeight
    clip: true

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    function byId(id) { return all.find(a => a.id === id); }

    // first matching rule wins; order = section order
    readonly property var groups: [
        { name: "Games",              cats: ["Game"] },
        { name: "Development",        cats: ["Development", "IDE", "TextEditor"] },
        { name: "Internet",           cats: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging"] },
        { name: "Media",              cats: ["AudioVideo", "Audio", "Video", "Player"] },
        { name: "Graphics",           cats: ["Graphics", "Photography"] },
        { name: "Office",             cats: ["Office", "Education", "Science"] },
        { name: "Settings & System",  cats: ["Settings", "System", "Monitor", "HardwareSettings"] },
        { name: "Utilities",          cats: ["Utility", "Accessories", "FileManager"] }
    ]
    function groupOf(a) {
        const c = a.categories ?? [];
        const g = groups.find(g => g.cats.some(x => c.includes(x)));
        return g ? g.name : "Other";
    }
    readonly property var sections: {
        const out = [];
        const recent = AppUsage.recentIds.map(byId).filter(a => a);
        const most = AppUsage.mostUsedIds.map(byId).filter(a => a);
        if (recent.length) out.push({ name: "Recent", apps: recent });
        if (most.length) out.push({ name: "Most used", apps: most });
        const sorted = all.slice().sort((a, b) => a.name.localeCompare(b.name));
        for (const g of groups.map(g => g.name).concat(["Other"])) {
            const apps = sorted.filter(a => groupOf(a) === g);
            if (apps.length) out.push({ name: g, apps: apps });
        }
        return out;
    }

    ColumnLayout {
        id: col
        width: view.width
        spacing: 6
        Repeater {
            model: view.sections
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                PText { text: modelData.name; font.bold: true; font.pixelSize: 12; color: Theme.accent; Layout.topMargin: 6 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: modelData.apps
                        delegate: Rectangle {
                            required property var modelData
                            width: 120; height: 92; radius: Theme.radius
                            color: h.containsMouse ? Theme.bg2 : Theme.bg1
                            Column {
                                anchors.centerIn: parent; spacing: 6
                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 36; height: 36; sourceSize: Qt.size(36, 36)
                                    source: Quickshell.iconPath(modelData.icon, true)
                                }
                                PText {
                                    width: 110; horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name; font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { AppUsage.launch(modelData); view.launched(); }
                            }
                        }
                    }
                }
            }
        }
    }
}
