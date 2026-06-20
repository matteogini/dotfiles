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
    property var wifiItems: []
    property real animHeight: animRect.height
    
    property string selectedSsid: ""
    property var seenSsids: ({})
    
    WlrLayershell.keyboardFocus: show ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    
    visible: show || animRect.opacity > 0
    
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: {
            if (selectedSsid !== "") {
                passInput.forceActiveFocus();
            } else {
                listView.forceActiveFocus();
            }
        }
    }
    
    onShowChanged: {
        if (show) {
            selectedSsid = "";
            wifiModel.clear();
            wifiItems = [];
            seenSsids = {};
            pGetWifi.running = true;
            focusTimer.start();
        }
    }
    
    Process {
        id: pGetWifi
        command: ["sh", "-c", "nmcli --get-values IN-USE,SSID,SECURITY,SIGNAL dev wifi list"]
        stdout: SplitParser {
            onRead: data => {
                var d = data.trim();
                if (d.length > 0) {
                    var parts = d.split(":");
                    if (parts.length >= 4) {
                        var inUse = parts[0];
                        var signal = parseInt(parts.pop(), 10);
                        var sec = parts.pop();
                        var ssid = parts.slice(1).join(":");
                        var secure = (sec !== "" && sec !== "--");
                        var connected = (inUse === "*");
                        if (ssid !== "" && !seenSsids[ssid]) {
                            seenSsids[ssid] = true;
                            wifiItems.push({"ssid": ssid, "secure": secure, "connected": connected, "signal": isNaN(signal) ? 0 : signal});
                        }
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running && rootWindow.show) {
                wifiItems.sort(function(a, b) {
                    if (a.connected !== b.connected) {
                        return a.connected ? -1 : 1;
                    }
                    return b.signal - a.signal;
                });
                for (var i = 0; i < wifiItems.length; i++) {
                    wifiModel.append(wifiItems[i]);
                }
            }
        }
    }
    
    Process {
        id: pConnect
        property string ssid: ""
        property string pass: ""
        onRunningChanged: {
            if (running) {
                if (pass === "") {
                    command = ["nmcli", "dev", "wifi", "connect", ssid];
                } else {
                    command = ["nmcli", "dev", "wifi", "connect", ssid, "password", pass];
                }
            }
        }
    }
    
    Item {
        anchors.fill: parent
        focus: show
        Keys.onEscapePressed: {
            if (selectedSsid !== "") {
                selectedSsid = "";
                focusTimer.start();
            } else {
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
                anchors.margins: 16
                opacity: show ? 1.0 : 0.0
                clip: true
                Behavior on opacity { NumberAnimation { duration: (shellRoot && shellRoot.batteryMode) ? 0 : show ? 300 : 100; easing.type: Easing.InOutQuad } }

                ColumnLayout {
                    anchors.fill: parent
                spacing: 16
                
                Text {
                    text: selectedSsid === "" ? "Wi-Fi Networks" : "Connect to " + selectedSsid
                    color: shellRoot ? shellRoot.colFg : "white"
                    font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Password entry view
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: selectedSsid !== ""
                    spacing: 16
                    
                    TextField {
                        id: passInput
                        Layout.fillWidth: true
                        placeholderText: "Password..."
                        echoMode: TextInput.Password
                        color: shellRoot ? shellRoot.colFg : "white"
                        font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                        font.pixelSize: 14
                        background: Rectangle {
                            color: Qt.rgba(1,1,1,0.05)
                            radius: 12
                            border.color: passInput.activeFocus ? Qt.rgba(1,1,1,0.2) : "transparent"
                        }
                        Keys.onReturnPressed: {
                            pConnect.ssid = selectedSsid;
                            pConnect.pass = text;
                            pConnect.running = true;
                            rootWindow.show = false;
                        }
                        Keys.onEscapePressed: {
                            selectedSsid = "";
                            passInput.text = "";
                            focusTimer.start();
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 12
                            color: Qt.rgba(1,1,1,0.1)
                            Text { anchors.centerIn: parent; text: "Cancel"; color: "white" }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    selectedSsid = "";
                                    passInput.text = "";
                                    focusTimer.start();
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 12
                            color: Qt.rgba(0.2,0.6,1.0,0.8)
                            Text { anchors.centerIn: parent; text: "Connect"; color: "white"; font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    pConnect.ssid = selectedSsid;
                                    pConnect.pass = passInput.text;
                                    pConnect.running = true;
                                    rootWindow.show = false;
                                }
                            }
                        }
                    }
                }
                
                // Networks list view
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: selectedSsid === ""
                    model: ListModel { id: wifiModel }
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
                                text: model.secure ? "" : ""
                                color: shellRoot ? shellRoot.colFg : "white"
                                font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                                font.pixelSize: 12
                            }
                            Text {
                                text: model.ssid + (model.connected ? " (Connected)" : "")
                                color: model.connected ? "#00FF00" : (shellRoot ? shellRoot.colFg : "white")
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
                                if (model.secure) {
                                    selectedSsid = model.ssid;
                                    passInput.text = "";
                                    focusTimer.start();
                                } else {
                                    pConnect.ssid = model.ssid;
                                    pConnect.pass = "";
                                    pConnect.running = true;
                                    rootWindow.show = false;
                                }
                            }
                        }
                    }
                }
                }
            }
        }
    }
}
