pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

KeyboardPanel {
    id: root

    property var hostWidget: null
    anchorItem: hostWidget && hostWidget.button ? hostWidget.button : null
    bar: hostWidget ? hostWidget.bar : null
    property var settings: hostWidget ? hostWidget.settings : null
    
    owner: hostWidget || root
    property bool opened: false
    open: opened

    function toggle() {
        opened = !opened;
    }

    function close() {
        opened = false;
    }

    contentWidth: Style.space(250)
    contentHeight: Style.space(120)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(10)
        spacing: Style.space(10)

        Label {
            text: "Configuration OpenVPN"
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Label { text: "Statut :" }
            Label {
                text: (hostWidget && hostWidget.isConnected) ? "Connecté" : "Déconnecté"
                color: (hostWidget && hostWidget.isConnected) ? "#a6e3a1" : "#f38ba8"
            }
        }

        Button {
            text: (hostWidget && hostWidget.isConnected) ? "Se déconnecter" : "Se connecter"
            Layout.fillWidth: true
            onClicked: {
                if (hostWidget) {
                    hostWidget.isConnected = !hostWidget.isConnected;
                }
            }
        }
    }
}