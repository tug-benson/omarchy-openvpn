import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import Omarchy 1.0

Item {
    id: root
    width: 400
    height: 350
    property string selectedConfig: ""

    // Importation de fichier .ovpn
    Button {
        id: importButton
        text: "Importer un fichier .ovpn"
        width: parent.width
        height: 40
        anchors.centerIn: parent

        onClicked: {
            var file = Qt.quick.FileDialog.openFileUrl(Qt.DocumentsLocation, "Select .ovpn file")
            if (file) {
                selectedConfig = file.toLocalFile()
                console.log("Fichier sélectionné: " + selectedConfig)
            Omarchy.runScript("vpn-import", [selectedConfig])
            }
        }
    }

    // Section pour les informations de connexion
    Rectangle {
        id: credentialsSection
        width: parent.width
        height: 280
        y: importButton.y + importButton.height + 10
        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            text: "Configuration OpenVPN"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }

        Label {
            text: "Login:"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 30
        }

        TextField {
            id: loginField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 30
            placeholderText: "Entrez votre login"
        }

        Label {
            text: "Mot de passe:"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 60
        }

        PasswordField {
            id: passwordField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 60
            echoMode: PasswordField.Password
            placeholderText: "Entrez votre mot de passe"
        }

        Button {
            text: "Appliquer"
            width: 100
            height: 30
            anchors.right: parent.right - 20
            anchors.top: credentialsSection.top + 90
            onClicked: {
                console.log("Login: " + loginField.text)
                console.log("Mot de passe: ***")
                // Logique pour appliquer les informations de connexion
            Omarchy.runScript("vpn-apply-credentials", [loginField.text, passwordField.text]);
        }

        Label {
            text: "DNS (IP):"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 90
        }

        TextField {
            id: dnsField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 90
            placeholderText: "Exemple: 8.8.8.8"
        }

        Label {
            text: "Domaine de recherche:"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 120
        }

        TextField {
            id: domainField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 120
            placeholderText: "Exemple: ~domain"
        }

        Label {
            text: "DNS (IP):"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 90
        }

        TextField {
            id: dnsField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 90
            placeholderText: "Exemple: 8.8.8.8"
        }

        Label {
            text: "Domaine de recherche:"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 120
        }

        TextField {
            id: domainField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 120
            placeholderText: "Exemple: ~domain"
        }

        Label {
            text: "Code TOTP (si nécessaire):"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 150
        }

        TextField {
            id: totpField
            width: 250
            anchors.left: parent.left + 80
            anchors.top: credentialsSection.top + 150
            placeholderText: "Entrez le code TOTP ici"
            echoMode: TextField.Normal
        }

        CheckBox {
            id: totpRequiredCheckBox
            text: "Code TOTP requis"
            anchors.left: parent.left + 20
            anchors.top: credentialsSection.top + 180
            anchors.right: parent.right - 20
        }

        Button {
            text: "Appliquer"
            width: 100
            height: 30
            anchors.right: parent.right - 20
            anchors.top: credentialsSection.top + 210
            onClicked: {
                console.log("Login: " + loginField.text);
                console.log("DNS: " + dnsField.text);
                console.log("Domaine: " + domainField.text);
                console.log("TOTP requis: " + totpRequiredCheckBox.checked);

            Omarchy.runScript("vpn-apply-credentials", [loginField.text, passwordField.text]);
            Omarchy.runScript("vpn-apply-dns", [dnsField.text, domainField.text]);

            // Si TOTP est requis, le script vpn-start s'en chargera automatiquement
            }
        }
    }
}
