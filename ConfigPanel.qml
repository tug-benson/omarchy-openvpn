import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitWidth: 300
    implicitHeight: 200

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            text: "OpenVPN Configuration"
            font.bold: true
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            font.color: "#333333"
        }

        RowLayout {
            spacing: 6
            anchors.margins: Qt.size(0, 4)

            Label { text: "Login:" ; font.pixelSize: 9 ; font.color: "#555555" }
            TextField {
                id: loginField
                Layout.fillWidth: true
                font.pixelSize: 9
                placeholderText: "username"
            }
        }

        RowLayout {
            spacing: 6
            Label { text: "Password:" ; font.pixelSize: 9 ; font.color: "#555555" }
            TextField {
                id: passwordField
                Layout.fillWidth: true
                font.pixelSize: 9
                echoMode: TextInput.Password
                placeholderText: "password"
            }
        }

        RowLayout {
            spacing: 6
            Label { text: "DNS IP:" ; font.pixelSize: 9 ; font.color: "#555555" }
            TextField {
                id: dnsField
                Layout.fillWidth: true
                font.pixelSize: 9
                placeholderText: "DNS server"
            }
        }

        RowLayout {
            spacing: 6
            Label { text: "Domain:" ; font.pixelSize: 9 ; font.color: "#555555" }
            TextField {
                id: domainField
                Layout.fillWidth: true
                font.pixelSize: 9
                placeholderText: "search domain (optional)"
            }
        }

        Button {
            text: "Apply DNS"
            Layout.alignment: Qt.AlignRight
            font.pixelSize: 9
            onClicked: {
                if (dnsField.text && domainField.text) {
                    Omarchy.runScript("vpn-apply-dns", [dnsField.text, domainField.text])
                    console.log("DNS applied")
                }
            }
        }

        Button {
            text: "Import .ovpn"
            Layout.alignment: Qt.AlignRight
            font.pixelSize: 9
            onClicked: {
                var result = Omarchy.showOpenFileName("Select OpenVPN config", "OpenVPN files (*.ovpn);;All files (*)")
                if (result) {
                    Omarchy.runScript("vpn-import-ovpn", [result])
                    console.log("Imported: " + result)
                }
            }
        }

        Button {
            text: "Paste from Clipboard"
            Layout.alignment: Qt.AlignRight
            font.pixelSize: 9
            onClicked: {
                var content = Omarchy.readPipe("wl-paste" 2>/dev/null || echo "")
                if (content && content.includes("-----BEGIN OpenVPN")) {
                    var home = Omarchy.homePath || "/home/user"
                    var tmpFile = home + "/.config/openvpn/client-import.ovpn"
                    Omarchy.writeFile(tmpFile, content)
                    Omarchy.runScript("vpn-import-ovpn", [tmpFile])
                    console.log("Pasted from clipboard")
                }
            }
        }

        Button {
            text: "Save"
            Layout.alignment: Qt.AlignRight
            font.pixelSize: 9
            onClicked: {
                console.log("Configuration saved")
            }
        }
    }
}