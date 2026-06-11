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
    property string brightnessLevel: "0%"
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

    Process { id: pWifiToggle; command: ["sh", "-c", "if [ \"$(nmcli radio wifi)\" = \"enabled\" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"] }
    Process { id: pBtToggle; command: ["sh", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then rfkill block bluetooth; else rfkill unblock bluetooth; fi"] }
    Process { id: pWifiOn; command: ["nmcli", "radio", "wifi", "on"] }
    Process { id: pWifiOff; command: ["nmcli", "radio", "wifi", "off"] }
    Process { id: pBtOn; command: ["rfkill", "unblock", "bluetooth"] }
    Process { id: pBtOff; command: ["rfkill", "block", "bluetooth"] }

    Process { id: pSpotPrev; command: ["playerctl", "--player=spotify", "previous"] }

    Process {
        id: pBright
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}'"]
        running: true
        stdout: SplitParser { onRead: text => root.brightnessLevel = text.trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: pBright.running = true }

    Process {
        id: pBrightSet
        property string target: "50%"
        command: ["brightnessctl", "s", target]
    }

    Process { id: pSpotPlay; command: ["playerctl", "--player=spotify", "play-pause"] }
    Process { id: pSpotNext; command: ["playerctl", "--player=spotify", "next"] }
    Process { id: pGpu; command: ["sh", "-c", "supergfxctl -m Hybrid; hyprctl dispatch \"hl.dsp.exit()\""] }

    Process { id: pGpuInt; command: ["sh", "-c", "supergfxctl -m Integrated; hyprctl dispatch \"hl.dsp.exit()\""] }
    Process { id: pGpuHyb; command: ["sh", "-c", "supergfxctl -m Hybrid; hyprctl dispatch \"hl.dsp.exit()\""] }
    
    Process { id: pNoteHyprland; command: ["zeditor", "/home/matteo/.config/hypr"] }
    Process { id: pNoteWaybar; command: ["zeditor", "/home/matteo/.config/waybar/"] }
    Process { id: pNoteTofi; command: ["zeditor", "/home/matteo/.config/tofi/"] }
    Process { id: pNoteKitty; command: ["zeditor", "/home/matteo/.config/kitty"] }
    Process { id: pNoteFoot; command: ["zeditor", "/home/matteo/.config/foot"] }
    Process { id: pNoteGhostty; command: ["zeditor", "/home/matteo/.config/ghostty"] }
    Process { id: pNoteFish; command: ["zeditor", "/home/matteo/.config/fish"] }
    Process { id: pNoteFastfetch; command: ["zeditor", "/home/matteo/.config/fastfetch"] }

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
        property real customWidth: 0
        default property alias customContent: contentBox.data
        
        Layout.preferredHeight: root.height
        Layout.preferredWidth: show ? (customWidth > 0 ? customWidth + 16 : modText.implicitWidth + 16) : 0
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
            Item {
                id: contentBox
                anchors.centerIn: parent
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
            // Ultra-minimalism: Left side is intentionally empty
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
            id: rightLayout
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            Mod { 
                property int cap: parseInt(root.batteryCap)
                property bool isCrit: cap <= 15 && !root.batteryCharging
                property bool isWarn: cap <= 30 && cap > 15 && !root.batteryCharging
                
                text: {
                    if (root.batteryCharging) return ""; // plug
                    if (cap > 80) return ""; // full
                    if (cap > 60) return ""; // 3/4
                    if (cap > 40) return ""; // 1/2
                    if (cap > 20) return ""; // 1/4
                    return ""; // empty
                }
                textColor: {
                    if (isCrit) return root.colBg;
                    if (isWarn) return root.colFg;
                    if (root.batteryCharging) return root.colAccent;
                    return root.colFg;
                }
                
                bgColor: {
                    if (isCrit) return root.colAccent;
                    if (isWarn) return root.colHover;
                    return "transparent";
                }
                
                blink: isCrit
                show: !controlCenter.show
                onClicked: { controlCenter.show = true }
            }
        }
    }
}


    component ModernBatteryIcon: Item {
        id: battIcon
        property real level: 1.0
        property bool charging: false
        property color colFg: root.colFg
        
        implicitWidth: 32
        implicitHeight: 14
        
        Rectangle {
            id: outline
            width: 26
            height: 12
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.color: battIcon.colFg
            border.width: 1.5
            radius: 4
            opacity: 0.7
            
            Rectangle {
                id: fill
                x: 2
                y: 2
                width: Math.max(0, (parent.width - 4) * battIcon.level)
                height: parent.height - 4
                radius: 2
                color: {
                    if (battIcon.charging) return "#76B900";
                    if (battIcon.level <= 0.2) return "#FF3B30";
                    return battIcon.colFg;
                }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
        
        // The nub
        Rectangle {
            width: 3
            height: 6
            anchors.left: outline.right
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            color: battIcon.colFg
            opacity: 0.7
            radius: 1.5
        }
        
        // Charging bolt
        Text {
            visible: battIcon.charging
            text: ""
            font.pixelSize: 9
            color: "#ffffff"
            anchors.centerIn: outline
        }
    }


    component ModernSplitButton: Item {
        id: mbtn
        property string text
        property string iconText
        property bool isActive: false
        property color accent: root.colFg
        
        signal mainClicked()
        signal iconClicked()
        
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        
        Rectangle {
            anchors.fill: parent
            radius: 12
            color: mainMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
            border.color: "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        MouseArea {
            id: mainMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mbtn.mainClicked()
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 12
            spacing: 12
            
            // Icon Circle Box
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: mbtn.isActive ? mbtn.accent : Qt.rgba(1, 1, 1, 0.1)
                
                Text {
                    anchors.centerIn: parent
                    text: mbtn.iconText
                    color: mbtn.isActive ? "#ffffff" : root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 16
                }
                
                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: mbtn.iconClicked()
                }
                
                scale: iconMouse.containsPress ? 0.9 : (iconMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            Text { 
                text: mbtn.text
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }
            
            Text {
                text: ""
                color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.3)
                font.family: root.fontFamily
                font.pixelSize: 16
            }
        }
        
        scale: mainMouse.containsPress ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    }

    component ModernButton: MouseArea {
        id: mbtn
        property string text
        property string iconText
        property bool isActive: false
        property color accent: root.colFg
        
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        hoverEnabled: true
        
        Rectangle {
            anchors.fill: parent
            radius: 12
            color: mbtn.isActive ? Qt.rgba(mbtn.accent.r, mbtn.accent.g, mbtn.accent.b, 0.15) 
                                 : (mbtn.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))
            border.color: mbtn.isActive ? Qt.rgba(mbtn.accent.r, mbtn.accent.g, mbtn.accent.b, 0.3) : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: mbtn.iconText; color: mbtn.isActive ? mbtn.accent : root.colFg; font.family: root.fontFamily; font.pixelSize: 16 }
            Text { text: mbtn.text; color: mbtn.isActive ? mbtn.accent : root.colFg; font.family: root.fontFamily; font.pixelSize: 13; font.bold: true }
        }
        
        scale: containsPress ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    }

    component ModernSlider: Slider {
        id: mSlider
        Layout.fillWidth: true
        from: 0; to: 1.0
        
        background: Rectangle {
            x: mSlider.leftPadding
            y: mSlider.topPadding + mSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 8
            width: mSlider.availableWidth
            height: implicitHeight
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.1)
            Rectangle {
                width: mSlider.visualPosition * parent.width
                height: parent.height
                color: root.colFg
                radius: 4
            }
        }
        
        handle: Rectangle {
            x: mSlider.leftPadding + mSlider.visualPosition * (mSlider.availableWidth - width)
            y: mSlider.topPadding + mSlider.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: mSlider.pressed ? Qt.rgba(0.8, 0.8, 0.8, 1) : "#ffffff"
            scale: mSlider.pressed || mSlider.hovered ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
            
        }
    }

    PanelWindow {
        id: controlCenter
        
        anchors {
            top: true
            right: true
        }
        
        exclusionMode: ExclusionMode.Ignore
        


        property bool show: false
        


        
        // Fluid Animation Visibility Logic: Stay mapped until opacity is 0
        visible: show || animRect.opacity > 0
        
        // Increased size
        implicitWidth: 440
        implicitHeight: mainLayout.implicitHeight + 48 + root.height + 8
        color: "transparent"
        
        Item {
            anchors.fill: parent
            
            Rectangle {
                id: animRect
                anchors.fill: parent
                
                anchors.rightMargin: 12
                
                color: Qt.rgba(0.08, 0.08, 0.08, 0.95)
                radius: 16
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                
                // FLUID ANIMATION
                opacity: controlCenter.show ? 1.0 : 0.0
                scale: controlCenter.show ? 1.0 : 0.95
                y: controlCenter.show ? 0 : -20
                
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        id: mainLayout
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        
                    spacing: 24
                    
                    // Header: Clock & Date & Battery
                    RowLayout {
                        Layout.fillWidth: true
                        
                        ColumnLayout {
                            spacing: 4
                            Text {
                                id: clockText
                                color: root.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 28
                                font.bold: true
                                text: Qt.formatDateTime(new Date(), "HH:mm")
                                Timer {
                                    interval: 1000; running: true; repeat: true
                                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
                                }
                            }
                            Text {
                                color: root.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Battery Close Button
                        MouseArea {
                            property int cap: parseInt(root.batteryCap)
                            property bool isCrit: cap <= 15 && !root.batteryCharging
                            property bool isWarn: cap <= 30 && cap > 15 && !root.batteryCharging
                            
                            Layout.preferredHeight: 48
                            Layout.preferredWidth: battLayout.implicitWidth + 24
                            hoverEnabled: true
                            onClicked: { controlCenter.show = false }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            RowLayout {
                                id: battLayout
                                anchors.centerIn: parent
                                spacing: 10
                                Text { 
                                    text: {
                                        let cap = parseInt(root.batteryCap);
                                        if (root.batteryCharging) return "";
                                        if (cap > 80) return "";
                                        if (cap > 60) return "";
                                        if (cap > 40) return "";
                                        if (cap > 20) return "";
                                        return "";
                                    }
                                    color: {
                                        let cap = parseInt(root.batteryCap);
                                        let isCrit = cap <= 15 && !root.batteryCharging;
                                        let isWarn = cap <= 30 && cap > 15 && !root.batteryCharging;
                                        return isCrit ? root.colCrit : (isWarn ? "#FFA500" : (root.batteryCharging ? "#76B900" : root.colFg));
                                    }
                                    font.family: root.fontFamily
                                    font.pixelSize: 18 
                                }
                                Text { 
                                    text: root.batteryCap + "%"
                                    color: root.colFg
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true 
                                }
                            }
                            
                            scale: containsPress ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        }
                    }
                    
                    // System Stats (Moved under clock)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Text { text: "󱐋 " + root.powerDraw + "W"; color: root.colMuted; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                        Text { text: " " + root.temperature + "°"; color: parseInt(root.temperature) >= 80 ? root.colCrit : root.colMuted; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                        Text { text: "󰮯 " + root.updates; color: root.colMuted; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; visible: parseInt(root.updates) > 0 }
                    }
                    
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1,1,1,0.1) }
                    
                    // Spotify Media Player
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.spotifyStatus !== "offline"
                        
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: ""; color: "#1DB954"; font.family: root.fontFamily; font.pixelSize: 18 }
                            Text {
                                text: root.spotifyText
                                color: root.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            Item { Layout.fillWidth: true }
                            ModernButton { Layout.preferredWidth: 48; Layout.preferredHeight: 48; iconText: "󰒮"; onClicked: { pSpotPrev.running = true } }
                            ModernButton { Layout.preferredWidth: 64; Layout.preferredHeight: 48; iconText: root.spotifyStatus === "Playing" ? "󰏤" : "󰐊"; isActive: root.spotifyStatus === "Playing"; accent: "#1DB954"; onClicked: { pSpotPlay.running = true } }
                            ModernButton { Layout.preferredWidth: 48; Layout.preferredHeight: 48; iconText: "󰒭"; onClicked: { pSpotNext.running = true } }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1,1,1,0.1); visible: root.spotifyStatus !== "offline" }

                    // Sliders
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        // Volume
                        RowLayout {
                            spacing: 16
                            Text { text: ""; color: root.colFg; font.family: root.fontFamily; font.pixelSize: 18 }
                            ModernSlider {
                                value: parseInt(root.volumeOut) / 100.0
                                onMoved: {
                                    pVolSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)]
                                    pVolSet.running = true
                                }
                            }
                            
                        }
                        
                        // Mic
                        RowLayout {
                            spacing: 16
                            Text { text: ""; color: root.colFg; font.family: root.fontFamily; font.pixelSize: 18 }
                            ModernSlider {
                                value: parseInt(root.volumeMic) / 100.0
                                onMoved: {
                                    pVolSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", value.toFixed(2)]
                                    pVolSet.running = true
                                }
                            }
                            
                        }
                        // Brightness
                        RowLayout {
                            spacing: 16
                            Text { text: "󰃠"; color: root.colFg; font.family: root.fontFamily; font.pixelSize: 18 }
                            ModernSlider {
                                value: parseInt(root.brightnessLevel) / 100.0
                                onMoved: {
                                    pBrightSet.target = Math.round(value * 100) + "%"
                                    pBrightSet.running = true
                                }
                            }
                            
                        }

                    }
                    
                    // Toggles Row 1
                    RowLayout {
                        spacing: 12
                        Layout.fillWidth: true
                        
                        ModernSplitButton {
                            text: "Bluetooth"
                            iconText: root.bluetoothStatus === "on" ? "" : "󰂲"
                            isActive: root.bluetoothStatus === "on"
                            accent: "#007AFF"
                            onMainClicked: { pBlueberry.running = true; controlCenter.show = false }
                            onIconClicked: { pBtToggle.running = true }
                        }
                        
                        ModernSplitButton {
                            text: root.wifiText === "Disconnected" ? "Wi-Fi" : root.wifiText
                            iconText: root.wifiIcon
                            isActive: root.wifiText !== "Disconnected"
                            accent: "#007AFF"
                            onMainClicked: { pNmtui.running = true; controlCenter.show = false }
                            onIconClicked: { pWifiToggle.running = true }
                        }
                    }
                    
                    // Toggles Row 2
                    RowLayout {
                        spacing: 12
                        Layout.fillWidth: true
                        
                        ModernButton {
                            text: root.gpuMode
                            iconText: "󰢮"
                            isActive: root.gpuMode === "Hybrid" || root.gpuMode === "Nvidia"
                            accent: "#76B900"
                            id: btnGpu; onClicked: { gpuPopup.show = !gpuPopup.show; notesPopup.show = false }
                        }
                        ModernButton {
                            text: "Configs"
                            iconText: ""
                            id: btnNotes; onClicked: { notesPopup.show = !notesPopup.show; gpuPopup.show = false }
                    }
                    
                    } // End mainLayout

                    } // End Item wrapper
            }
        }
    }
}

    PopupWindow {
        id: gpuPopup
        anchor {
            window: controlCenter
            rect: Qt.rect(btnGpu.mapToItem(null, 0, 0).x, btnGpu.mapToItem(null, 0, 0).y, btnGpu.width, btnGpu.height)
            edges: Edges.Left | Edges.Top
            gravity: Edges.Left | Edges.Bottom
        }
        
        property bool show: false
        visible: show || animRectGpu.opacity > 0
        
        implicitWidth: 200
        implicitHeight: layoutGpu.implicitHeight + 32
        color: "transparent"
        
        Item {
            anchors.fill: parent
            
            Rectangle {
                id: animRectGpu
                anchors.fill: parent
                
                anchors.rightMargin: 12
                
                color: Qt.rgba(0.08, 0.08, 0.08, 0.95)
                radius: 16
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                
                opacity: gpuPopup.show ? 1.0 : 0.0
                scale: gpuPopup.show ? 1.0 : 0.95
                x: gpuPopup.show ? 0 : 20
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                
                ColumnLayout {
                    id: layoutGpu
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 12
                    
                    
                    ModernButton { text: "Integrated"; iconText: "󰍛"; onClicked: { pGpuInt.running = true; gpuPopup.show = false; controlCenter.show = false } }
                    ModernButton { text: "Hybrid"; iconText: "󰢮"; onClicked: { pGpuHyb.running = true; gpuPopup.show = false; controlCenter.show = false } }
                }
            }
        }
    }

    PopupWindow {
        id: notesPopup
        anchor {
            window: controlCenter
            rect: Qt.rect(btnNotes.mapToItem(null, 0, 0).x, btnNotes.mapToItem(null, 0, 0).y, btnNotes.width, btnNotes.height)
            edges: Edges.Left | Edges.Top
            gravity: Edges.Left | Edges.Bottom
        }
        
        property bool show: false
        visible: show || animRectNotes.opacity > 0
        
        implicitWidth: 340
        implicitHeight: layoutNotes.implicitHeight + 32
        color: "transparent"
        
        Item {
            anchors.fill: parent
            
            Rectangle {
                id: animRectNotes
                anchors.fill: parent
                
                anchors.rightMargin: 12
                
                color: Qt.rgba(0.08, 0.08, 0.08, 0.95)
                radius: 16
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                
                opacity: notesPopup.show ? 1.0 : 0.0
                scale: notesPopup.show ? 1.0 : 0.95
                x: notesPopup.show ? 0 : 20
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                
                ColumnLayout {
                    id: layoutNotes
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 12
                    
                    
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8
                        
                        ModernButton { Layout.preferredHeight: 40; text: "Hyprland"; onClicked: { pNoteHyprland.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Waybar"; onClicked: { pNoteWaybar.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Tofi"; onClicked: { pNoteTofi.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Kitty"; onClicked: { pNoteKitty.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Foot"; onClicked: { pNoteFoot.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Ghostty"; onClicked: { pNoteGhostty.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Fish"; onClicked: { pNoteFish.running = true; notesPopup.show = false; controlCenter.show = false } }
                        ModernButton { Layout.preferredHeight: 40; text: "Fastfetch"; onClicked: { pNoteFastfetch.running = true; notesPopup.show = false; controlCenter.show = false } }
                    }
                }
            }
        }
    }

    }
