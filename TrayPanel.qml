import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: trayRoot
    implicitWidth: 24
    implicitHeight: 24

    Label {
        text: "VPN"
        anchors.centerIn: parent
        font.pixelSize: 10
    }
}
