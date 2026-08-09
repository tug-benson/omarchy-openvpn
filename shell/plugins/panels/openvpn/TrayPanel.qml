import QtQuick 2.15
import QtQuick.Controls 2.15
import Omarchy 1.0

TrayIcon {
    id: trayIcon
    width: 24
    height: 24
    icon: vpnService.isRunning ? "vpn-up.png" : "vpn-down-light.png"

    Omarchy.Service {
        id: vpnService
        source: "Service.qml"
    }

    connections: [
        Connection {
            target: vpnService
            method: onRunningChanged
            function() {
                trayIcon.icon = vpnService.isRunning ? "vpn-up.png" : "vpn-down-light.png"
            }
        }
    ]

    Menu {
        MenuItem {
            text: "Configurer VPN"
            onTriggered: Omarchy.openPanel("ConfigPanel.qml")
        }
        MenuItem {
            text: vpnService.isRunning ? "Déconnecter" : "Connecter"
            onTriggered: {
                if (vpnService.isRunning) {
                    vpnService.stop()
                } else {
                    vpnService.start()
                }
            }
        }
        MenuItem {
            text: "Quitter"
            onTriggered: Omarchy.close()
        }
    }
}
