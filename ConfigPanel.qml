import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitWidth: 300
    implicitHeight: 150

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
        
        Button {
            text: "Save"
            Layout.alignment: Qt.AlignRight
            onClicked: {
                // Here we would save the login/password
                console.log("Saved login/password configuration.")
            }
        }
    }
}