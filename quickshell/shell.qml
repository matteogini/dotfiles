import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

ShellRoot {
    PanelWindow {
    id: root

    property color colBg: "#000000"
    property color colFg: "#ffffff"
    property color colAccent: "#ffffff"
    property color colMuted: Qt.rgba(1, 1, 1, 0.4)
    property color colHover: Qt.rgba(1, 1, 1, 0.1)
    property color colCrit: "#ff0000"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 10 // Reduced font size to match waybar 9px

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 24
    color: colBg

    // State properties
    property string powerDraw: "0.0"
    property string temperature: "0"
    property string updates: "0"
    property string batteryCap: "100"
    property bool batteryCharging: false
    property string gpuMode: "Unknown"
    property string volumeOut: "0%"
    property bool volumeMuted: false
    property string volumeMic: "0%"
    property bool micMuted: false
    property string bluetoothStatus: "off"
    property string spotifyStatus: "offline"
    property string spotifyText: ""
    property string wifiIcon: "󰤯"
    property string wifiText: "Disconnected"

    // Click Actions
    Process { id: pPavu; command: ["pavucontrol"] }
    Process { id: pMicMute; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"] }
    Process { id: pVolSet } // Dynamic volume setter
    Process { id: pBlueberry; command: ["blueberry"] }
    Process { id: pSpotPrev; command: ["playerctl", "--player=spotify", "previous"] }
    Process { id: pSpotPlay; command: ["playerctl", "--player=spotify", "play-pause"] }
    Process { id: pSpotNext; command: ["playerctl", "--player=spotify", "next"] }
    Process { id: pGpu; command: ["sh", "-c", "supergfxctl -m Hybrid; hyprctl dispatch \"hl.dsp.exit()\""] }
    Process { id: pNotes; command: ["sh", "-c", "zeditor ~/.config/waybar/config.jsonc"] }
    Process { id: pNmtui; command: ["kitty", "-e", "nmtui"] }

    // Background Process Loops
    Process {
        command: ["sh", "-c", "while true; do awk '{line[NR]=$1} END {printf \"%.1f\", (line[1] * line[2]) / 1000000000000}' /sys/class/power_supply/BAT1/current_now /sys/class/power_supply/BAT1/voltage_now 2>/dev/null || echo '0.0'; echo; sleep 10; done"]
        running: true; stdout: SplitParser { onRead: data => root.powerDraw = data.trim() }
    }
    Process {
        command: ["sh", "-c", "while true; do temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); echo $((temp / 1000)); sleep 10; done"]
        running: true; stdout: SplitParser { onRead: data => root.temperature = data.trim() }
    }
    Process {
        command: ["sh", "-c", "while true; do checkupdates 2>/dev/null | wc -l; sleep 3600; done"]
        running: true; stdout: SplitParser { onRead: data => root.updates = data.trim() }
    }
    Process {
        command: ["sh", "-c", "while true; do cap=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0); acad=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo 0); echo \"$cap $acad\"; sleep 60; done"]
        running: true; stdout: SplitParser { 
            onRead: data => {
                var parts = data.trim().split(" ");
                root.batteryCap = parts[0];
                root.batteryCharging = (parts[1] === "1");
            }
        }
    }
    Process {
        command: ["sh", "-c", "while true; do supergfxctl -g 2>/dev/null || echo '?'; sleep 10; done"]
        running: true; stdout: SplitParser { onRead: data => root.gpuMode = data.trim() }
    }
    Process {
        command: ["sh", "-c", "while true; do wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null; sleep 2; done"]
        running: true; stdout: SplitParser { 
            onRead: data => {
                var d = data.trim();
                root.volumeMuted = d.includes("[MUTED]");
                var m = d.match(/[0-9.]+/);
                if (m) root.volumeOut = Math.round(parseFloat(m[0]) * 100) + "%";
            }
        }
    }
    Process {
        command: ["sh", "-c", "while true; do wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null; sleep 2; done"]
        running: true; stdout: SplitParser { 
            onRead: data => {
                var d = data.trim();
                root.micMuted = d.includes("[MUTED]");
                var m = d.match(/[0-9.]+/);
                if (m) root.volumeMic = Math.round(parseFloat(m[0]) * 100) + "%";
            }
        }
    }
    Process {
        command: ["sh", "-c", "while true; do bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'; sleep 10; done"]
        running: true; stdout: SplitParser { onRead: data => root.bluetoothStatus = data.trim() }
    }
    Process {
        command: ["sh", "-c", "while true; do sig=$(LC_ALL=C nmcli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2); if [ -z \"$sig\" ]; then echo 'disc'; else echo \"$sig\"; fi; sleep 10; done"]
        running: true; stdout: SplitParser { 
            onRead: data => {
                var d = data.trim();
                if (d === 'disc') { root.wifiIcon = "󰤮"; root.wifiText = "Disconnected"; }
                else {
                    var s = parseInt(d);
                    root.wifiText = s + "%";
                    if (s > 80) root.wifiIcon = "󰤨";
                    else if (s > 60) root.wifiIcon = "󰤥";
                    else if (s > 40) root.wifiIcon = "󰤢";
                    else if (s > 20) root.wifiIcon = "󰤟";
                    else root.wifiIcon = "󰤯";
                }
            }
        }
    }
    Process {
        command: ["sh", "-c", "while true; do status=$(playerctl --player=spotify status 2>/dev/null || echo 'offline'); if [ \"$status\" != 'offline' ]; then text=$(playerctl --player=spotify metadata --format '{{title}} - {{artist}}' 2>/dev/null); echo \"$status|$text\"; else echo 'offline|'; fi; sleep 2; done"]
        running: true; stdout: SplitParser { 
            onRead: data => {
                var p = data.split("|");
                root.spotifyStatus = p[0].trim();
                root.spotifyText = p[1] ? p[1].trim() : "";
            }
        }
    }


    // A helper to make clickable modules easily
    component Mod: MouseArea {
        id: modRoot
        property string text
        property color textColor: root.colFg
        property color bgColor: "transparent"
        property bool blink: false
        property bool show: true
        
        Layout.preferredHeight: root.height
        Layout.preferredWidth: show ? (modText.implicitWidth + 16) : 0
        Behavior on Layout.preferredWidth { 
            NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
        }
        
        visible: Layout.preferredWidth > 0
        clip: true
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            color: parent.containsMouse ? root.colHover : parent.bgColor
            Behavior on color { ColorAnimation { duration: 200 } }
            
            SequentialAnimation on opacity {
                running: modRoot.blink
                loops: Animation.Infinite
                NumberAnimation { to: 0.1; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }

        Item {
            anchors.centerIn: parent
            width: modText.width
            height: modText.height
            scale: parent.containsPress ? 0.85 : (parent.containsMouse ? 1.1 : 1.0)
            Behavior on scale { 
                NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } 
            }
            
            Text {
                id: modText
                text: parent.parent.text
                color: parent.parent.textColor
                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        // --- LEFT ---
        RowLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            // Stats Group Drawer
            MouseArea {
                id: statsDrawer
                hoverEnabled: true
                Layout.preferredHeight: root.height
                Layout.preferredWidth: statsRow.implicitWidth
                RowLayout {
                    id: statsRow
                    anchors.fill: parent
                    spacing: 0
                    
                    // Handle
                    Item { Layout.preferredWidth: 8; Layout.preferredHeight: root.height }
                    
                    // Drawer contents
                    RowLayout {
                        spacing: 0
                        clip: true
                        Layout.preferredWidth: statsDrawer.containsMouse ? implicitWidth : 0
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        Mod { text: " 󱐋 " + root.powerDraw + "W"; textColor: root.colAccent }
                        Mod { text: " " + root.temperature + "°"; textColor: parseInt(root.temperature) >= 80 ? root.colCrit : root.colFg }
                        Mod { text: "󰮯 " + root.updates; show: parseInt(root.updates) > 0 }
                        Mod { text: ""; onClicked: { pNotes.running = true } }
                    }
                }
            }

            // Spotify
            RowLayout {
                spacing: 0
                visible: root.spotifyStatus !== "offline"
                Mod { text: "󰒮"; onClicked: { pSpotPrev.running = true } }
                Mod { text: root.spotifyStatus === "Playing" ? "󰏤" : "󰐊"; textColor: root.colAccent; onClicked: { pSpotPlay.running = true } }
                Mod { text: "󰒭"; onClicked: { pSpotNext.running = true } }
                Text {
                    text: root.spotifyText.length > 35 ? root.spotifyText.substring(0, 32) + "..." : root.spotifyText
                    color: root.colMuted
                    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    Layout.leftMargin: 8
                }
            }
        }

        // --- CENTER ---
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            // Workspaces - strictly matching waybar behaviour (only existing ones shown)
            Repeater {
                model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                Mod {
                    property var ws: Hyprland.workspaces.values.find(w => w.id === modelData)
                    property bool isActive: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === modelData
                    
                    text: modelData
                    // Active workspaces are white (colFg), inactive but populated are grey (colMuted)
                    textColor: isActive ? root.colFg : root.colMuted
                    // Only show if the workspace actually exists/has windows, or is currently focused
                    show: ws !== undefined || isActive
                    
                    onClicked: Hyprland.dispatch("workspace " + modelData)
                }
            }
        }

        // --- RIGHT ---
        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            Mod { 
                property int cap: parseInt(root.batteryCap)
                property bool isCrit: cap <= 15 && !root.batteryCharging
                property bool isWarn: cap <= 30 && cap > 15 && !root.batteryCharging
                
                text: {
                    // format-plugged: " " -> hide text if full/not discharging? 
                    // waybar assumes plugged = AC connected. We'll use status.
                    if (root.batteryCharging) return "+" + root.batteryCap;
                    return root.batteryCap;
                }
                
                textColor: {
                    if (isCrit) return root.colBg;         // color: @bg
                    if (isWarn) return root.colFg;         // color: @fg
                    if (root.batteryCharging) return root.colAccent; // color: @accent
                    return root.colMuted;                  // color: alpha(@fg, 0.4)
                }
                
                bgColor: {
                    if (isCrit) return root.colAccent;     // background-color: @accent
                    if (isWarn) return root.colHover;      // background-color: rgba(255, 255, 255, 0.2)
                    return "transparent";
                }
                
                blink: isCrit
                show: !root.batteryCharging
            }

            // Tools Group Drawer
            MouseArea {
                id: toolsDrawer
                hoverEnabled: true
                Layout.preferredHeight: root.height
                Layout.preferredWidth: toolsRow.implicitWidth
                RowLayout {
                    id: toolsRow
                    anchors.fill: parent
                    spacing: 0
                    
                    // Drawer contents (expanding smoothly via width animation)
                    RowLayout {
                        spacing: 0
                        clip: true
                        Layout.preferredWidth: toolsDrawer.containsMouse ? implicitWidth : 0
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        
                        Mod { text: "󰢮 " + root.gpuMode; onClicked: { pGpu.running = true } }
                        
                        // Wifi
                        Mod {
                            text: root.wifiIcon + " " + root.wifiText
                            textColor: root.wifiText === "Disconnected" ? root.colCrit : root.colFg
                            onClicked: { pNmtui.running = true }
                        }
                        
                        Mod { 
                            text: (root.volumeMuted ? " " : " ") + root.volumeOut
                            textColor: root.volumeMuted ? root.colMuted : root.colFg
                            onClicked: { controlCenter.show = !controlCenter.show }
                        }
                        
                        MouseArea {
                            property bool show: true
                            Layout.preferredHeight: root.height
                            Layout.preferredWidth: show ? (micModText.implicitWidth + 16) : 0
                            Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                            clip: true
                            visible: Layout.preferredWidth > 0
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    pMicMute.running = true
                                } else {
                                    pPavu.running = true
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? root.colHover : "transparent"
                            }
                            Item {
                                anchors.centerIn: parent
                                width: micModText.width
                                height: micModText.height
                                scale: parent.containsPress ? 0.85 : (parent.containsMouse ? 1.1 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                                
                                Text {
                                    id: micModText
                                    text: root.micMuted ? " " : " "
                                    color: root.micMuted ? root.colMuted : root.colFg
                                    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }

                        Mod {
                            text: root.bluetoothStatus === "on" ? " on" : "󰂲"
                            textColor: root.bluetoothStatus === "on" ? root.colFg : root.colMuted
                            onClicked: { pBlueberry.running = true }
                        }

                        Mod {
                            id: clockMod
                            text: Qt.formatDateTime(new Date(), "HH:mm")
                            Timer {
                                interval: 1000; running: true; repeat: true
                                onTriggered: clockMod.text = Qt.formatDateTime(new Date(), "HH:mm")
                            }
                        }
                    }
                    
                    // Handle
                    Item { Layout.preferredWidth: 8; Layout.preferredHeight: root.height }
                }
            }
        }
    }
}

    PopupWindow {
        id: controlCenter
        anchor.window: root
        anchor.edges: Edges.Bottom | Edges.Right
        
        property bool show: false
        visible: show
        
        implicitWidth: 320
        implicitHeight: show ? layout.implicitHeight + 32 : 0
        Behavior on implicitHeight { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        
        color: Qt.rgba(0.05, 0.05, 0.05, 0.95)
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(1,1,1,0.1)
            border.width: 1
            radius: 8
        }
        
        ColumnLayout {
            id: layout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 20
            
            Text {
                text: "Control Center"
                color: root.colFg
                font { family: root.fontFamily; pixelSize: 14; bold: true }
            }
            
            // Volume
            RowLayout {
                spacing: 12
                Text { text: ""; color: root.colFg; font.family: root.fontFamily }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1.0
                    value: parseInt(root.volumeOut) / 100.0
                    onMoved: {
                        pVolSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)]
                        pVolSet.running = true
                    }
                }
                Text { text: root.volumeOut; color: root.colFg; font.family: root.fontFamily; Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight }
            }
            
            // Mic
            RowLayout {
                spacing: 12
                Text { text: ""; color: root.colFg; font.family: root.fontFamily }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1.0
                    value: parseInt(root.volumeMic) / 100.0
                    onMoved: {
                        pVolSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", value.toFixed(2)]
                        pVolSet.running = true
                    }
                }
                Text { text: root.volumeMic; color: root.colFg; font.family: root.fontFamily; Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight }
            }
            
            // Toggles Row
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                
                Button {
                    Layout.fillWidth: true
                    text: root.bluetoothStatus === "on" ? " Bluetooth: On" : "󰂲 Bluetooth: Off"
                    onClicked: { pBlueberry.running = true; controlCenter.show = false }
                }
                
                Button {
                    Layout.fillWidth: true
                    text: "󰤨 Wi-Fi"
                    onClicked: { pNmtui.running = true; controlCenter.show = false }
                }
            }
            
            Button {
                Layout.fillWidth: true
                text: "Open Pavucontrol"
                onClicked: { pPavu.running = true; controlCenter.show = false }
            }
        }
    }
}
