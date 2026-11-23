import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

// Drops down under the clock: month grid, today highlighted, arrows change month.
Popup {
    id: panel
    open: Panels.calendarOpen
    anchors.top: true          // top only = horizontally centred, under the clock
    boxWidth: 330
    boxHeight: 330

    SystemClock { id: clock; precision: SystemClock.Hours }
    property date shown: new Date()
    onOpenChanged: if (open) shown = new Date()

    readonly property int firstDow: Qt.locale().firstDayOfWeek % 7          // 0 = Sunday
    readonly property var cells: {
        const y = shown.getFullYear(), m = shown.getMonth();
        const lead = (new Date(y, m, 1).getDay() - firstDow + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - lead + i);
            out.push({ day: d.getDate(), inMonth: d.getMonth() === m,
                       today: d.toDateString() === clock.date.toDateString() });
        }
        return out;
    }
    function step(n) { panel.shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1); }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            IconCircle { icon: "\u{f0141}"; implicitWidth: 28; implicitHeight: 28; tint: Theme.fgDim
                         MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panel.step(-1) } }
            PText {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.bold: true
                text: panel.shown.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                MouseArea { anchors.fill: parent; onClicked: panel.shown = new Date() }   // back to today
            }
            IconCircle { icon: "\u{f0142}"; implicitWidth: 28; implicitHeight: 28; tint: Theme.fgDim
                         MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panel.step(1) } }
        }
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 7; rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: 7
                delegate: PText {
                    required property int index
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10; color: Theme.fgDim
                    text: Qt.locale().dayName((panel.firstDow + index) % 7, Locale.ShortFormat).slice(0, 2)
                }
            }
            Repeater {
                model: panel.cells
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: height / 2
                    color: modelData.today ? Theme.accent : "transparent"
                    PText {
                        anchors.centerIn: parent; text: modelData.day; font.pixelSize: 12
                        color: modelData.today ? Theme.bg0 : (modelData.inMonth ? Theme.fg : Theme.bg3)
                        font.bold: modelData.today
                    }
                }
            }
        }
    }
    // wheel over the panel changes month
    WheelHandler { onWheel: e => panel.step(e.angleDelta.y > 0 ? -1 : 1) }
}
