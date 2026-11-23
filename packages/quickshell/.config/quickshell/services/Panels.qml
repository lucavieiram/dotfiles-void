pragma Singleton
import Quickshell
import QtQuick

// Which popup is open. Left panel has tabs: "apps" | "themes" | "walls".
Singleton {
    property bool leftOpen: false
    property bool rightOpen: false
    property bool powerOpen: false
    property bool calendarOpen: false
    property bool audioOpen: false
    property bool wifiOpen: false
    property string leftTab: "apps"
    property bool leftCentered: false   // keybinds open the hub mid-screen; the logo opens it under the bar
    // screen of the bar that was clicked; null = keybind, use the focused output
    property var screen: null
    readonly property bool anyOpen: leftOpen || rightOpen || powerOpen || calendarOpen || audioOpen || wifiOpen

    function closeAll() { leftOpen = false; rightOpen = false; powerOpen = false; calendarOpen = false; audioOpen = false; wifiOpen = false; }
    // same tab again closes; another tab switches
    function left(tab, centered) {
        const close = leftOpen && leftTab === tab;
        closeAll(); leftTab = tab; leftCentered = centered ?? false; leftOpen = !close;
    }
    function toggleLeft() { left(leftTab, false); }
    function toggleAudio() { const o = !audioOpen; closeAll(); audioOpen = o; }
    function toggleWifi() { const o = !wifiOpen; closeAll(); wifiOpen = o; }
    function toggleCalendar() { const o = !calendarOpen; closeAll(); calendarOpen = o; }
    function togglePower() { const o = !powerOpen; closeAll(); powerOpen = o; }
    function toggleRight() { const o = !rightOpen; closeAll(); rightOpen = o; }
}
