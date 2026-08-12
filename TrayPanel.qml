import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: trayRoot
    implicitWidth: 24
    implicitHeight: 24

    Label {
        text: "\udb85\udd46" // Nerd Font icon for VPN
        anchors.centerIn: parent
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16
    }
}
