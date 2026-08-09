import QtQuick 2.15
import QtQuick.Controls 2.15
import Omarchy 1.0

Item {
    id: root
    width: 100
    height: 30

    property bool isRunning: false

    Omarchy.Service {
        id: vpnService
        source: "Service.qml"
    }

    property alias isRunning: vpnService.isRunning

    Image {
        id: statusImage
        width: 24
        height: 24
        source: isRunning ? "vpn-up.png" : "vpn-down-light.png"
        fillMode: Image.PreserveAspectFit
        anchors.left: parent.left
        anchors.leftMargin: 5
    }

    Button {
        id: toggleButton
        width: 30
        height: 30
        anchors.right: parent.right
        anchors.rightMargin: 5
        text: ""
        onClicked: {
            if (isRunning) {
                vpnService.stop()
            } else {
                vpnService.start()
            }
        }
    }

    connections: [
        Connection {
            target: vpnService
            method: onRunningChanged
            function() {
                statusImage.source = isRunning ? "vpn-up.png" : "vpn-down-light.png"
            }
        }
    ]

    Menu {
        id: configMenu
        anchors.right: toggleButton.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter

        MenuItem {
            text: "Configurer VPN"
            onTriggered: {
                Omarchy.openPanel("ConfigPanel.qml")
            }
        }
    }
}
