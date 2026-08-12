import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitWidth: layout.implicitWidth + 10
    implicitHeight: 24

    // Variable d'état factice pour l'instant
    property bool isConnected: false

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Label {
            // Utilisation de l'icône de Nerd Font
            text: "\udb85\udd46" 
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 16
            color: isConnected ? "#a6e3a1" : "#f38ba8" // Vert si connecté, rouge si déconnecté (Catppuccin colors)
        }

        Label {
            text: isConnected ? "VPN ON" : "VPN OFF"
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Pour tester, on inverse simplement l'état
            isConnected = !isConnected;
            console.log(isConnected ? "Connecting VPN..." : "Disconnecting VPN...");
        }
    }
}