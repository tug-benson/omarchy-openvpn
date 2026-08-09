import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import Omarchy 1.0

Item {
    id: root
    width: 100
    height: 30

    property bool isRunning: false

    // Import du composant de service
    Omarchy.Service {
        id: vpnService
        source: "shell/plugins/panels/openvpn/Service.qml"
    }

    // État du VPN
    property alias isRunning: vpnService.isRunning

    // Image de l'état
    Image {
        id: statusImage
        width: 24
        height: 24
        source: isRunning ? "shell/plugins/panels/openvpn/vpn-up.png" : "shell/plugins/panels/openvpn/vpn-down-light.png"
        fillMode: Image.PreserveAspectFit
        anchors.left: parent.left
        anchors.leftMargin: 5
    }

    // Bouton pour activer/désactiver le VPN
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

    // Connexion pour mettre à jour l'état
    connections: [
        Connection {
            target: vpnService
            method: onRunningChanged
            function() {
                statusImage.source = isRunning ? "shell/plugins/panels/openvpn/vpn-up.png" : "shell/plugins/panels/openvpn/vpn-down-light.png"
            }
        }
    ]

    // Menu contextuel pour la configuration
    Menu {
        id: configMenu
        anchors.right: toggleButton.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter

        MenuItem {
            text: "Configurer VPN"
            onTriggered: {
                Omarchy.openPanel("shell/plugins/panels/openvpn/ConfigPanel.qml")
            }
        }
    }
}
