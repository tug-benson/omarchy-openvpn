pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "openvpn"

    // ── Service access ──
    readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
        ? (bar.shell.serviceFor("io.github.tug-benson.openvpn") || bar.shell.serviceFor("openvpn")) : null
    readonly property bool isConnected: service ? service.connected : false
    readonly property bool isBusy: service ? service.busy : false
    readonly property Item button: buttonItem

    // ── Panel injection ──
    function injectPanel() {
        var target = panelLoader.item
        if (!target) return
        if ("hostWidget" in target) target.hostWidget = root
        if ("anchorItem" in target) target.anchorItem = buttonItem
        if ("bar" in target) target.bar = root.bar
        if ("settings" in target) target.settings = root.settings
    }

    function togglePanel() {
        if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
    }

    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

    function open() {
        if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
    }

    function close() {
        if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
    }

    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

    function closeForPopoutSwitch() {
        if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
    }

    // ── Layout ──
    implicitWidth: buttonItem.implicitWidth
    implicitHeight: barSize

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()

    // ── Bar button ──
    BarIconButton {
        id: buttonItem
        anchors.fill: parent
        bar: root.bar
        // Nerd Font: 󰌆 (VPN shield connected) / 󰌊 (VPN shield disconnected)
        text: root.isConnected ? "󰌆" : "󰌊"
        tooltipText: root.isBusy ? "OpenVPN: Connecting..."
                   : root.isConnected ? "OpenVPN: Connected"
                   : "OpenVPN: Disconnected"
        active: root.isConnected

        onPressed: function(b) {
            root.togglePanel()
        }
    }

    // ── Panel loader ──
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
