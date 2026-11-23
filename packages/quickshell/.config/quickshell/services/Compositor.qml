pragma Singleton
import Quickshell
import Quickshell.I3
import Quickshell.Io
import QtQuick
import "icons.mjs" as Icons

// The only Sway-specific file. A Hyprland/niri variant re-implements:
//   workspaces: [{ num, name, focused, urgent, icons:[glyph] }]
//   focus(num), focusedScreen
Singleton {
    id: root

    // workspace name -> [glyph, ...]; filled from `swaymsg -t get_tree`
    property var appsByWs: ({})
    // output holding the focused window/workspace, also from get_tree
    // (I3.focusedMonitor stays empty on this build, so it cannot be used)
    property string focusedOutput: ""

    readonly property var workspaces: I3.workspaces.values
        .filter(w => w.num >= 0)
        .map(w => ({
            num: w.num, name: w.name, focused: w.focused, urgent: w.urgent,
            glyph: Icons.wsGlyph(w), icons: root.appsByWs[w.name] ?? []
        }))
        .sort((a, b) => a.num - b.num)

    // focused output; if unknown, the external monitor when one is connected, else the laptop
    readonly property var focusedScreen:
        Quickshell.screens.find(s => s.name === focusedOutput)
        ?? Quickshell.screens.find(s => !s.name.startsWith("eDP"))
        ?? Quickshell.screens[0]

    function focus(num) { I3.dispatch("workspace number " + num); }

    function parseTree(json) {
        const out = {};
        let focusedOut = "";
        function walk(node, ws, output) {
            if (node.type === "output") output = node.name;
            if (node.focused && output && output !== "__i3") focusedOut = output;
            if (node.type === "workspace") ws = node.name;
            const kids = (node.nodes ?? []).concat(node.floating_nodes ?? []);
            if (ws && kids.length === 0 && (node.app_id || node.window_properties)) {
                (out[ws] = out[ws] ?? []).push(
                    Icons.iconFor(node.app_id ?? "", node.window_properties?.class ?? ""));
            }
            kids.forEach(k => walk(k, ws, output));
        }
        try { walk(JSON.parse(json), null, ""); } catch (e) { return; }
        root.appsByWs = out;
        if (focusedOut) root.focusedOutput = focusedOut;
    }

    Process {
        id: tree
        command: ["swaymsg", "-t", "get_tree", "-r"]
        stdout: StdioCollector { onStreamFinished: root.parseTree(text) }
    }
    Timer { id: debounce; interval: 80; onTriggered: tree.running = true }
    Connections {
        target: I3
        function onRawEvent(event) { debounce.restart(); }
    }
    // shortcut: I3 may not subscribe to window events; a 2 s poll covers it. Drop if rawEvent proves enough.
    Timer { interval: 2000; running: true; repeat: true; onTriggered: if (!tree.running) tree.running = true }
    Component.onCompleted: tree.running = true
}
