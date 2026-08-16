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

    contentWidth: Style.space(280)
    contentHeight: Style.space(180)

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
            Label { text: "Interface :" }
            Label {
                id: ifaceLabel
                text: (hostWidget && hostWidget.isConnected) ? "tun0" : "--"
                color: "#cddb87"
            }
        }

        RowLayout {
            Label { text: "Statut :" }
            Label {
                text: (hostWidget && hostWidget.isConnected) ? "Connecté" : "Déconnecté"
                color: (hostWidget && hostWidget.isConnected) ? "#a6e3a1" : "#f38ba8"
            }
        }

        RowLayout {
            Label { text: "Traffic :" }
            Label {
                id: trafficLabel
                text: (hostWidget && hostWidget.isConnected) ? loadTraffic() : "--"
                color: "#82aaff"
                font.pixelSize: 11
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

    function loadTraffic() {
        if (!hostWidget || !hostWidget.isConnected) return "--"
        var output =Omarchy.readPipe("cat /proc/net/dev | grep tun0 | awk '{print $2, $10}'")
        if (!output) return "--"
        var parts = output.split(" ")
        if (parts.length < 2) return "--"
        var rx = parseInt(parts[0])
        var tx = parseInt(parts[1])
        function formatBytes(b) {
            if (b >= 1073741824) return (b / 1073741824).toFixed(2) + " Go"
            if (b >= 1048576) return (b / 1048576).toFixed(2) + " Mo"
            if (b >= 1024) return (b / 1024).toFixed(2) + " Ko"
            return b + " octets"
        }
        return "Rx: " + formatBytes(rx) + " | Tx: " + formatBytes(tx)
    }
}