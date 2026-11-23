pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Launch history for the Apps tab: { "<desktop id>": { count, last } } in ~/.cache/quickshell/app-usage.json
Singleton {
    id: root
    property var data: ({})

    function launch(entry) {
        const d = Object.assign({}, data);
        const cur = d[entry.id] ?? { count: 0, last: 0 };
        d[entry.id] = { count: cur.count + 1, last: Date.now() };
        data = d;
        file.setText(JSON.stringify(d));
        entry.execute();
    }
    function ids(key, n) {
        return Object.keys(data).sort((a, b) => data[b][key] - data[a][key]).slice(0, n);
    }
    readonly property var recentIds: ids("last", 8)
    readonly property var mostUsedIds: ids("count", 8)

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.cache/quickshell/app-usage.json"
        atomicWrites: true
        onLoaded: { try { root.data = JSON.parse(text()); } catch (e) { root.data = {}; } }
    }
}
