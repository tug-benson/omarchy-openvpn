import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitWidth: 320
    implicitHeight: 220

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            text: "OpenVPN Configuration"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Label { text: "Login:" ; Layout.preferredWidth: 60 }
            TextField {
                id: loginField
                Layout.fillWidth: true
                placeholderText: "Enter username"
            }
        }

        RowLayout {
            Label { text: "Password:" ; Layout.preferredWidth: 60 }
            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Enter password"
                echoMode: TextInput.Password
            }
        }

        RowLayout {
            Label { text: "DNS IP:" ; Layout.preferredWidth: 60 }
            TextField {
                id: dnsField
                Layout.fillWidth: true
                placeholderText: "Enter DNS IP address"
            }
        }

        RowLayout {
            Label { text: "Domain:" ; Layout.preferredWidth: 60 }
            TextField {
                id: domainField
                Layout.fillWidth: true
                placeholderText: "Enter search domain (optional)"
            }
        }

        Button {
            text: "Apply DNS"
            Layout.alignment: Qt.AlignRight
            onClicked: {
                if (dnsField.text && domainField.text) {
                    Omarchy.runScript("vpn-apply-dns", [dnsField.text, domainField.text])
                    console.log("DNS applied: " + dnsField.text + " / " + domainField.text)
                }
            }
        }

        Button {
            text: "Save"
            Layout.alignment: Qt.AlignRight
            onClicked: {
                console.log("Saved login/password configuration.")
            }
        }
    }
}