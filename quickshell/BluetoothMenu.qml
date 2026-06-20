import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: rootWindow
    
    property bool show: false
    property var shellRoot
    property var btItems: []
    property real animHeight: animRect.height
    
    WlrLayershell.keyboardFocus: show ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    
    visible: show || animRect.opacity > 0

    Process {
        id: pListBt
        command: ["bash", "-c", "for dev in $(bluetoothctl devices | awk '{print $2}'); do info=$(bluetoothctl info $dev); name=$(echo \"$info\" | awk -F'Name: ' '/Name:/ {print $2}'); connected=$(echo \"$info\" | awk -F'Connected: ' '/Connected:/ {print $2}'); echo \"$dev|$name|$connected\"; done"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line === "") return;
                var parts = line.split('|');
                if (parts.length >= 3) {
                    var mac = parts[0];
                    var connectedStr = parts.pop().trim();
                    var connected = (connectedStr === "yes");
                    var name = parts.slice(1).join("|");
                    if (name !== "") {
                        btItems.push({mac: mac, name: name, connected: connected});
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                btModel.clear();
                btItems.sort(function(a, b) {
                    if (a.connected !== b.connected) {
                        return a.connected ? -1 : 1;
                    }
                    return a.name.localeCompare(b.name);
                });
                for (var i = 0; i < btItems.length; i++) {
                    btModel.append(btItems[i]);
                }
                if (btModel.count > 0) {
                    listView.currentIndex = 0;
                }
                if (rootWindow.show) {
                    focusTimer.start();
                }
            }
        }
    }

    Process {
        id: pConnect
        property string targetMac: ""
        command: targetMac !== "" ? ["bluetoothctl", "connect", targetMac] : ["echo"]
    }

    Process {
        id: pDisconnect
        property string targetMac: ""
        command: targetMac !== "" ? ["bluetoothctl", "disconnect", targetMac] : ["echo"]
    }

    onShowChanged: {
        if (show) {
            btItems = [];
            btModel.clear();
            pListBt.running = true;
        }
    }
    
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: listView.forceActiveFocus()
    }
    
    Item {
        id: btMenuContent
        anchors.fill: parent
        focus: show

        Keys.onEscapePressed: {
            show = false;
        }
        
        Keys.onReturnPressed: connectCurrent()
        Keys.onEnterPressed: connectCurrent()
        
        function connectCurrent() {
            if (listView.currentIndex >= 0 && listView.currentIndex < btModel.count) {
                var item = btModel.get(listView.currentIndex);
                if (item.connected) {
                    pDisconnect.targetMac = item.mac;
                    pDisconnect.running = true;
                } else {
                    pConnect.targetMac = item.mac;
                    pConnect.running = true;
                }
                show = false;
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: show
            onClicked: show = false
        }
        
        Rectangle {
            id: animRect
            anchors.top: parent.top
            anchors.topMargin: show ? 16 : (shellRoot && shellRoot.isBarMode ? 0 : 4)
            anchors.horizontalCenter: parent.horizontalCenter
            
            width: show ? 360 : (shellRoot ? shellRoot.notchWidth + 32 : 120)
            height: show ? 280 : 32
            
            color: Qt.rgba(0.08, 0.08, 0.08, 0.95)
            radius: show ? 24 : (shellRoot && shellRoot.isBarMode ? 0 : 16)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: show ? 1 : 0
            
            opacity: (!show && height <= 36) ? 0.0 : 1.0
            
            Behavior on radius { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 450 : 300; easing.type: show ? Easing.OutBack : Easing.OutExpo; easing.overshoot: show ? 1.2 : 0 } }
            Behavior on width { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 450 : 300; easing.type: show ? Easing.OutBack : Easing.OutExpo; easing.overshoot: show ? 1.2 : 0 } }
            Behavior on height { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 450 : 300; easing.type: show ? Easing.OutBack : Easing.OutExpo; easing.overshoot: show ? 1.2 : 0 } }
            Behavior on anchors.topMargin { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 450 : 300; easing.type: show ? Easing.OutBack : Easing.OutExpo; easing.overshoot: show ? 1.2 : 0 } }
            
            Item {
                anchors.fill: parent
                opacity: show ? 1.0 : 0.0
                clip: true
                Behavior on opacity { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 300 : 100; easing.type: Easing.InOutQuad } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    Text {
                        text: "Bluetooth Devices"
                        color: shellRoot ? shellRoot.colFg : "white"
                        font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ListView {
                        id: listView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ListModel { id: btModel }
                        spacing: 4
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 48
                            radius: 12
                            color: listView.currentIndex === index || ma.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                Text {
                                    text: ""
                                    color: model.connected ? "#1DB954" : (shellRoot ? shellRoot.colFg : "white")
                                    font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: model.name + (model.connected ? " (Connected)" : "")
                                    color: model.connected ? "#1DB954" : (shellRoot ? shellRoot.colFg : "white")
                                    font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                                    font.pixelSize: 12
                                    font.bold: model.connected
                                    Layout.fillWidth: true
                                }
                            }
                            
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    listView.currentIndex = index;
                                    var mac = model.mac;
                                    if (model.connected) {
                                        pDisconnect.targetMac = mac;
                                        pDisconnect.running = true;
                                    } else {
                                        pConnect.targetMac = mac;
                                        pConnect.running = true;
                                    }
                                    show = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
