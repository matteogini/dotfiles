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
    property var allApps: []
    property real animHeight: animRect.height
    
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
        onTriggered: searchInput.forceActiveFocus()
    }

    onShowChanged: {
        if (show) {
            searchInput.text = "";
            filterApps("");
            if (allApps.length === 0) {
                pGetApps.running = true;
            }
            focusTimer.start();
        }
    }
    
    function filterApps(query) {
        appModel.clear();
        var q = query.toLowerCase();
        var max = 50; // show max 50 for performance
        var count = 0;
        for (var i = 0; i < allApps.length; i++) {
            if (allApps[i].name.toLowerCase().includes(q)) {
                appModel.append(allApps[i]);
                count++;
                if (count >= max) break;
            }
        }
        listView.currentIndex = 0;
    }
    
    Process {
        id: pGetApps
        command: ["python3", "/home/matteo/.config/quickshell/get_apps.py"]
        stdout: SplitParser {

            onRead: data => {
                try {
                    rootWindow.allApps = JSON.parse(data);
                    if (rootWindow.show) rootWindow.filterApps("");
                } catch(e) {
                    console.log("Error parsing apps: " + e);
                }
            }
        }
    }
    
    Process { id: pExec }
    
    Item {
        anchors.fill: parent
        
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
            
            width: show ? 400 : (shellRoot ? shellRoot.notchWidth + 32 : 120)
            height: show ? 320 : 32
            
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
                
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search apps..."
                    color: shellRoot ? shellRoot.colFg : "white"
                    font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                    font.pixelSize: 14
                    background: Rectangle {
                        color: Qt.rgba(1,1,1,0.05)
                        radius: 12
                        border.color: searchInput.activeFocus ? Qt.rgba(1,1,1,0.2) : "transparent"
                    }
                    onTextEdited: filterApps(text)
                    Keys.onDownPressed: listView.incrementCurrentIndex()
                    Keys.onUpPressed: listView.decrementCurrentIndex()
                    Keys.onReturnPressed: {
                        if (listView.currentIndex >= 0 && listView.currentIndex < appModel.count) {
                            var app = appModel.get(listView.currentIndex);
                            pExec.running = false;
                            pExec.command = ["/home/matteo/.config/quickshell/launch_app.sh", app.cmd];
                            pExec.running = true;
                            show = false;
                        }
                    }
                    Keys.onEscapePressed: show = false
                }
                
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ListModel { id: appModel }
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
                                text: model.name
                                color: shellRoot ? shellRoot.colFg : "white"
                                font.family: shellRoot ? shellRoot.fontFamily : "sans-serif"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                        
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                listView.currentIndex = index;
                                pExec.running = false;
                                pExec.command = ["/home/matteo/.config/quickshell/launch_app.sh", model.cmd];
                                pExec.running = true;
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
