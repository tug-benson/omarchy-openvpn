import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: trayRoot
    implicitWidth: 24
    implicitHeight: 24

    Label {
        text: "󰴽" // Nerd Font icon for VPN (U+F0D3D)
        anchors.centerIn: parent
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16
    }
}
