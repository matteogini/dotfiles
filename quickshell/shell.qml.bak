import Quickshell               // core stuff
import QtQuick                  // basic UI elements
import Quickshell.Wayland       // for PanelWindow
import Quickshell.Hyprland      // hyprland IPC access
import QtQuick.Layouts          // for RowLayout
import Quickshell.Io            // for process type

/*
documentation:
https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/

pattern:
- process to run a command
- SplitParser to parse output
- timer to refresh periodically
*/

// doesn't dock - doesn't reserve space
/*
FloatingWindow {
    visible: true
    width: 200
    height: 100

    Text {
        anchors.centerIn: parent
        text: "quickshell element"
        color: "#0db9d7"
        font.pixelSize: 18
    }
}
*/

PanelWindow {
    id: root

    // theme - define one, use everywhere
    property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 18

    // system data
    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property int memUsage: 0

    // run shell commands with process
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]

        // SplitParser calls onRead for each line of output
        stdout: SplitParser {
            onRead: data => {
                // parse /proc/stats...
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (lastCpuTotal > 0) {
                    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                }
                lastCpuTotal = total
                lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grem Mem"]
        stdout: SplitParser {
            onRead: data => {
                var ports = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // timer to refresh every 2s
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg

    /*
    Text {
        anchors.centerIn: parent
        text: "my new bar"
        color: "#a9b1d6"
        font.pixelSize: 14
    }
    */

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Repeater creates 9 copies, each gets an index (0-8)
        Repeater {
            model: 9

            Text {
                // Live data from hyprland
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

                text: index + 1
                // cyan = active, blue = has windows, gray = empty
                color: isActive ? root.colCyan : (ws ? root.colBlue : root.colMuted)
                font { pixelSize: 14; bold: true }

                // clicl to switch workspace
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "CPU: " + cpuUsage + "%"
            color: root.colYellow
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        // separator
        Rectangle { width: 2; height: 16; color: root.colMuted }

        Text {
            text: "MEM: " + memUsage + "%"
            color: root.colYellow
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 2; height: 16; color: root.colMuted }

        Text {
            id: clock
            // text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
            text: Qt.formatDateTime(new Date(), "HH:mm")
            color: root.colBlue

            Timer {
                interval: 1000
                running: true
                repeat: true
                // onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MM dd - HH:mm")
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }
}
