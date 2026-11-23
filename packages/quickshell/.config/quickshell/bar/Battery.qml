import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services

Pill {
    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    visible: dev?.isLaptopBattery ?? false
    PText {
        text: charging ? "\u{f0084}" : ["\u{f008e}", "\u{f007b}", "\u{f007d}", "\u{f007f}", "\u{f0081}", "\u{f0079}"][Math.min(5, Math.floor(pct / 20))]
        color: pct < 15 && !charging ? Theme.red : Theme.green
    }
    PText { text: Math.round(pct) + "%" }
}
