import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitWidth: 200
    implicitHeight: 80

    // Service.qml would manage the connection logic here
    // Service { id: vpnService }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Label {
            text: "OpenVPN"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Switch {
            id: vpnSwitch
            text: checked ? "Connected" : "Disconnected"
            Layout.alignment: Qt.AlignHCenter
            onCheckedChanged: {
                if (checked) {
                    console.log("Connecting to VPN...")
                    // vpnService.connect()
                } else {
                    console.log("Disconnecting from VPN...")
                    // vpnService.disconnect()
                }
            }
        }
    }
}