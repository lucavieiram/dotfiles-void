pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon (replaces dunst). History = server.trackedNotifications.
Singleton {
    id: root
    property bool dnd: false
    property var popups: []          // [{ n: Notification, at: ms }]
    readonly property var history: server.trackedNotifications.values
    readonly property int timeout: 5000

    function dismissAll() { history.slice().forEach(n => n.dismiss()); popups = []; }
    function dropPopup(n) { popups = popups.filter(p => p.n !== n); }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = root.popups.concat([{ n: n, at: Date.now() }]);
            n.closed.connect(() => root.dropPopup(n));
        }
    }
    Timer {
        interval: 500; repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now();
            root.popups = root.popups.filter(p =>
                p.n.urgency === NotificationUrgency.Critical || now - p.at < root.timeout);
        }
    }
}
