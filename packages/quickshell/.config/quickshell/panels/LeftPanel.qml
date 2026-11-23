import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// Hub: side rail (Apps / Themes / Walls) + one search box shared by the tabs.
// Apps launches programs, Themes runs theme-apply, Walls sets the wallpaper.
Popup {
    id: panel
    open: Panels.leftOpen
    // centred when opened from a keybind (no anchors = layer surface sits mid-screen)
    anchors.top: !Panels.leftCentered
    anchors.left: !Panels.leftCentered
    margins.left: Theme.gap
    // opened from a keybind (centred) = wide for every tab, so switching tabs never resizes;
    // the logo opens the compact version under the bar
    readonly property bool wide: Panels.leftCentered
    readonly property bool grouped: tab === "apps" && q === ""
    boxWidth: wide ? 860 : 420
    boxHeight: wide ? 640 : 580

    readonly property string tab: Panels.leftTab
    readonly property string q: search.text.toLowerCase()
    property var themes: []
    property var wallpapers: []   // absolute paths
    property var clips: []        // raw `cliphist list` lines: "<id>\t<preview>"
    property bool colorsFromWall: false
    property var themeWalls: ({})   // theme -> wallpaper it would set (theme-apply --walls)
    // Walls tab shows the current theme's folder (Wallpapers/<theme>/) or everything
    property bool allWalls: false
    readonly property string themeDir: "/Wallpapers/" + Theme.name + "/"
    readonly property bool themeHasWalls: wallpapers.some(w => w.includes(themeDir))

    onOpenChanged: { search.text = ""; list.currentIndex = 0; allWalls = false; }
    onTabChanged: { search.text = ""; list.currentIndex = 0; }

    function apply(args) { Quickshell.execDetached([Theme.applyCmd].concat(args)); }

    Process {
        command: [Theme.applyCmd, "--list"]
        running: panel.open
        stdout: StdioCollector { onStreamFinished: panel.themes = text.split("\n").filter(s => s) }
    }
    Process {
        command: [Theme.applyCmd, "--walls"]
        running: panel.open
        stdout: StdioCollector { onStreamFinished: { try { panel.themeWalls = JSON.parse(text); } catch (e) {} } }
    }

    Process {
        command: ["sh", "-c", "find -L \"$HOME/Pictures/Wallpapers\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) ! -name 'current.*' | sort"]
        running: panel.open
        stdout: StdioCollector { onStreamFinished: panel.wallpapers = text.split("\n").filter(s => s) }
    }

    Process {
        command: ["cliphist", "list"]
        running: panel.open && panel.tab === "clip"
        stdout: StdioCollector { onStreamFinished: panel.clips = text.split("\n").filter(s => s) }
    }

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay && a.name.toLowerCase().includes(q))
        .sort((a, b) => a.name.localeCompare(b.name))

    // rows for the list tabs: { title, subtitle, icon, image, current, run() }
    readonly property var rows: tab === "apps"
        ? apps.map(a => ({ title: a.name, subtitle: a.genericName ?? "", image: Quickshell.iconPath(a.icon, true),
                           icon: "", current: false, run: () => { AppUsage.launch(a); Panels.closeAll(); } }))
        : tab === "clip"
        ? clips.filter(c => c.toLowerCase().includes(q)).slice(0, 200).map(c => ({
                           title: c.split("\t").slice(1).join(" ").replace(/\s+/g, " ").slice(0, 80),
                           subtitle: "", image: "", icon: "\u{f014c}", current: false,
                           run: () => { Panels.closeAll();
                                        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", c]); } }))
        : themes.filter(t => t.includes(q)).map(t => ({
                           title: t, subtitle: Theme.name === t ? "Current" : "", image: "", icon: "\u{f03d8}",
                           thumb: panel.themeWalls[t] ?? "",
                           current: Theme.name === t, run: () => panel.apply([t]) }))

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // rail
        Rectangle {
            Layout.fillHeight: true; implicitWidth: 64
            color: Theme.bg1; radius: Theme.radius + 4
            Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14; spacing: 14
                Repeater {
                    model: [ { id: "apps", icon: "\u{f003b}", label: "Apps" },
                             { id: "themes", icon: "\u{f03d8}", label: "Themes" },
                             { id: "walls", icon: "\u{f021f}", label: "Walls" },
                             { id: "clip", icon: "\u{f014c}", label: "Clip" } ]
                    delegate: Column {
                        required property var modelData
                        readonly property bool sel: panel.tab === modelData.id
                        spacing: 3
                        IconCircle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            icon: modelData.icon; filled: sel; tint: sel ? Theme.accent : Theme.fgDim
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Panels.leftTab = modelData.id }
                        }
                        PText { text: modelData.label; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter
                                color: sel ? Theme.accent : Theme.fgDim }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12
            spacing: 10

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 38; radius: height / 2; color: Theme.bg1
                IconCircle { id: mag; icon: ""; implicitWidth: 28; implicitHeight: 28
                             anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: search
                    anchors { left: mag.right; leftMargin: 10; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize
                    focus: panel.open
                    PText { text: "Search"; color: Theme.fgDim; visible: !search.text; anchors.verticalCenter: parent.verticalCenter }
                    onTextChanged: list.currentIndex = 0
                    Keys.onEscapePressed: Panels.closeAll()
                    Keys.onDownPressed: panel.tab === "walls" ? grid.moveCurrentIndexRight() : list.incrementCurrentIndex()
                    Keys.onUpPressed: panel.tab === "walls" ? grid.moveCurrentIndexLeft() : list.decrementCurrentIndex()
                    Keys.onTabPressed: Panels.leftTab = { apps: "themes", themes: "walls", walls: "clip", clip: "apps" }[panel.tab]
                    Keys.onReturnPressed: {
                        if (panel.tab === "walls") grid.currentItem?.pick();
                        else if (panel.grouped) { const a = DesktopEntries.applications.values.find(x => x.id === AppUsage.recentIds[0]);
                                                  if (a) { AppUsage.launch(a); Panels.closeAll(); } }
                        else panel.rows[list.currentIndex]?.run();
                    }
                }
            }

            // Apps + Themes
            ListView {
                id: list
                visible: panel.tab !== "walls" && !panel.grouped
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 6
                model: panel.rows
                highlightMoveDuration: 80
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width; height: 48; radius: height / 2
                    color: ListView.isCurrentItem || h.containsMouse ? Theme.bg2 : Theme.bg1
                    Row {
                        anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        IconCircle {
                            icon: modelData.icon; tint: Theme.orange
                            Image { anchors.centerIn: parent; width: 22; height: 22; sourceSize: Qt.size(22, 22)
                                    source: modelData.image; visible: modelData.image !== "" }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            PText { text: modelData.title; font.bold: true; font.pixelSize: 12; width: list.width - 90; elide: Text.ElideRight }
                            PText { text: modelData.subtitle; font.pixelSize: 10; visible: text !== ""
                                    color: modelData.current ? Theme.accent : Theme.fgDim }
                        }
                    }
                    Rectangle {
                        id: thumb
                        visible: (modelData.thumb ?? "") !== ""
                        width: 72; height: 38; radius: 10; clip: true; color: Theme.bg2
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        Image { anchors.fill: parent; source: thumb.visible ? "file://" + modelData.thumb : ""
                                sourceSize: Qt.size(144, 76); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    }
                    IconCircle {
                        visible: modelData.current; filled: true
                        icon: "\u{f012c}"; implicitWidth: 22; implicitHeight: 22
                        anchors { right: thumb.visible ? thumb.left : parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.run() }
                }
                PText { anchors.centerIn: parent; visible: list.count === 0; text: "Nothing found"; color: Theme.fgDim }
            }

            AppGrid {
                visible: panel.grouped
                Layout.fillWidth: true; Layout.fillHeight: true
                onLaunched: Panels.closeAll()
            }

            // Walls
            RowLayout {
                visible: panel.tab === "walls"
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [ { all: false, label: Theme.name }, { all: true, label: "All" } ]
                    delegate: Pill {
                        required property var modelData
                        readonly property bool sel: (panel.allWalls || !panel.themeHasWalls) === modelData.all
                        implicitHeight: 24
                        visible: modelData.all || panel.themeHasWalls
                        color: sel ? Theme.accent : Theme.bg1
                        onClicked: panel.allWalls = modelData.all
                        PText { text: modelData.label; font.pixelSize: 10; color: parent.parent.sel ? Theme.bg0 : Theme.fg }
                    }
                }
                Item { Layout.fillWidth: true }
                PText { text: "Colours from image"; font.pixelSize: 10; color: Theme.fgDim }
                Rectangle {
                    implicitWidth: 40; implicitHeight: 22; radius: 11
                    color: panel.colorsFromWall ? Theme.accent : Theme.bg2
                    Rectangle { width: 16; height: 16; radius: 8; y: 3; color: Theme.bg0
                                x: panel.colorsFromWall ? 21 : 3
                                Behavior on x { NumberAnimation { duration: Theme.anim } } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: panel.colorsFromWall = !panel.colorsFromWall }
                }
            }
            GridView {
                id: grid
                visible: panel.tab === "walls"
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                PText { anchors.centerIn: parent; visible: grid.count === 0; text: "Nothing found"; color: Theme.fgDim }
                cellWidth: width / (panel.wide ? 4 : 2); cellHeight: cellWidth * 10 / 16
                model: panel.wallpapers
                    .filter(w => panel.allWalls || !panel.themeHasWalls || w.includes(panel.themeDir))
                    .filter(w => w.split("/").pop().toLowerCase().includes(panel.q))
                delegate: Item {
                    id: cell
                    required property string modelData
                    readonly property string filePath: modelData
                    function pick() { panel.apply([panel.colorsFromWall ? "--wallpaper" : "--set-wallpaper", filePath]); }
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4; radius: 12; clip: true
                        color: Theme.bg1
                        border.width: wh.containsMouse || cell.GridView.isCurrentItem ? 2 : 0
                        border.color: Theme.accent
                        Image {
                            anchors.fill: parent; anchors.margins: 2
                            source: "file://" + cell.filePath
                            sourceSize.width: 360; sourceSize.height: 225
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true
                        }
                    }
                    MouseArea { id: wh; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: cell.pick() }
                }
            }
        }
    }
}
