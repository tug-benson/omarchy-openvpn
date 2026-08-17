pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import qs.Commons
import qs.Ui

KeyboardPanel {
    id: root

    property var hostWidget: null
    anchorItem: hostWidget && hostWidget.button ? hostWidget.button : null
    bar: hostWidget ? hostWidget.bar : null
    property var settings: hostWidget ? hostWidget.settings : null
    
    owner: hostWidget || root
    property bool opened: false
    open: opened

    function toggle() {
        opened = !opened;
    }

    function close() {
        opened = false;
    }

    contentWidth: Style.space(260)
    contentHeight: Style.space(140)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(8)
        spacing: Style.space(6)

        // Status row with connect button
        RowLayout {
            anchors.margins: Qt.size(0, 0)
            spacing: Style.space(4)

            Label {
                text: "OpenVPN"
                font.pixelSize: 11
                font.color: "#888888"
            }

            Button {
                id: connectBtn
                text: root.isConnected ? "Disconnect" : "Connect"
                implicitWidth: Style.space(60)
                implicitHeight: Style.space(24)
                font.pixelSize: 10
                enabled: true
                onClicked: {
                    root.isConnected = !root.isConnected
                }
            }
        }

        // Small separator
        Frame {
            implicitWidth: root.contentWidth
            implicitHeight: 1
            anchors.horizontalCenter: parent.horizontalCenter
            FrameStyle {}
        }

        // Stats row with small graphs
        RowLayout {
            spacing: Style.space(6)
            anchors.margins: Qt.size(0, 4)

            // Download graph
            Item {
                Layout.minimumWidth: Style.space(80)
                Layout.preferredWidth: Style.space(80)
                Layout.fillWidth: true

                // Download speed label
                Label {
                    id: downloadLabel
                    text: "--"
                    font.pixelSize: 9
                    font.color: "#88c0d0"
                    Layout.alignment: Qt.AlignLeft
                }

                // Small download bar/graph
                Item {
                    implicitHeight: Style.space(20)
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            implicitWidth: 3
                            height: (downloadValue / 100) * 20
                            color: "#88c0d0"
                            anchors.bottom: parent.bottom
                        }
                    }
                    property int downloadValue: root.loadDownload()
                }
            }

            // Upload graph
            Item {
                Layout.minimumWidth: Style.space(80)
                Layout.preferredWidth: Style.space(80)
                Layout.fillWidth: true

                // Upload speed label
                Label {
                    id: uploadLabel
                    text: "--"
                    font.pixelSize: 9
                    font.color: "#88c0d0"
                    Layout.alignment: Qt.AlignRight
                }

                // Small upload bar/graph
                Item {
                    implicitHeight: Style.space(20)
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            implicitWidth: 3
                            height: (uploadValue / 100) * 20
                            color: "#82aaff"
                            anchors.bottom: parent.bottom
                        }
                    }
                    property int uploadValue: root.loadUpload()
                }
            }
        }

        // Quick info row
        RowLayout {
            spacing: Style.space(6)
            anchors.margins: Qt.size(0, 4)

            Label { text: "IP:" ; font.pixelSize: 8 ; font.color: "#888888" }
            Label {
                id: ipLabel
                text: root.isConnected ? root.loadIP() : "--"
                font.pixelSize: 8
                font.color: "#ffffff"
            }
            Label { text:"/" ; font.pixelSize: 8 ; font.color: "#888888" }
            Label {
                id: ifaceLabel
                text: root.isConnected ? "tun0" : "--"
                font.pixelSize: 8
                font.color: "#888888"
            }
        }
    }

    function loadDownload() {
        if (!root.hostWidget || !root.hostWidget.isConnected) return 0
        var output = Omarchy.readPipe("cat /proc/net/dev | grep tun0 | awk '{print $2}'")
        if (!output) return 0
        var parts = output.split(" ")
        if (parts.length < 1) return 0
        return parseInt(parts[0])
    }

    function loadUpload() {
        if (!root.hostWidget || !root.hostWidget.isConnected) return 0
        var output = Omarchy.readPipe("cat /proc/net/dev | grep tun0 | awk '{print $10}'")
        if (!output) return 0
        var parts = output.split(" ")
        if (parts.length < 1) return 0
        return parseInt(parts[0])
    }

    function loadIP() {
        if (!root.hostWidget || !root.hostWidget.isConnected) return "--"
        var output = Omarchy.readPipe("ip -4 addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1")
        if (!output) return "--"
        return output.trim()
    }
}