pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "openvpn"

    implicitWidth: buttonItem.implicitWidth
    implicitHeight: barSize

    // Variable d'état pour le VPN (à connecter plus tard avec le Service)
    property bool isConnected: false

    function injectPanel() {
        var target = panelLoader.item
        if (!target) return
        if ("hostWidget" in target) target.hostWidget = root
        if ("anchorItem" in target) target.anchorItem = buttonItem
        if ("bar" in target) target.bar = root.bar
        if ("settings" in target) target.settings = root.settings
    }

    function togglePanel() {
        if (panelLoader.item && typeof panelLoader.item.toggle === "function") {
            panelLoader.item.toggle()
        } else {
            // Pour l'instant, on toggle juste l'état si le panel n'est pas prêt
            isConnected = !isConnected;
        }
    }

    BarIconButton {
        id: buttonItem
        anchors.fill: parent
        bar: root.bar
        text: "󰴽" // L'icône Nerd Font U+F0D3D
        tooltipText: isConnected ? "OpenVPN (Connecté)" : "OpenVPN (Déconnecté)"
        // On peut changer la couleur pour indiquer l'état
        foreground: isConnected ? "#a6e3a1" : (root.bar ? root.bar.textColor : "#ffffff")

        onPressed: function(b) {
            root.togglePanel()
        }
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }
}
