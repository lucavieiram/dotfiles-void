import QtQuick
import Quickshell
import qs.components
import qs.services

Pill {
    color: Panels.calendarOpen ? Theme.bg2 : Theme.bg1
    onClicked: { Panels.screen = QsWindow.window?.screen ?? null; Panels.toggleCalendar(); }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PText { text: "\u{f0954}"; color: Theme.orange }
    PText { text: Qt.formatDateTime(clock.date, "HH:mm") }
}
