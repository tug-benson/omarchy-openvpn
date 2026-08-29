pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

ColumnLayout {
    id: root
    spacing: Style.space(6)
    property var service: null
    onServiceChanged: Qt.callLater(syncConnChecks)
    property var hostPanel: null

    function scriptPath(name) {
        return Qt.resolvedUrl("bin/" + name).toString().replace(/^file:\/\//, "")
    }

    // ── Import process ──
    Process {
        id: filePicker
        command: ["zenity", "--file-selection", "--title=Select a .ovpn file", "--file-filter=OpenVPN | *.ovpn"]
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            if (code === 0) {
                var p = stdout.text.trim()
                if (p && root.service) root.service.importProfile(p)
            }
            if (root.hostPanel) Qt.callLater(function() { root.hostPanel.open() })
        }
    }

    // ── Profile ──
    Label { text: "Profile"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Label {
            Layout.fillWidth: true
            text: (root.service && root.service.activeProfileName) ? root.service.activeProfileName : "—"
            font.family: Style.font.family; font.pixelSize: Style.font.body
            color: Color.foreground
            elide: Text.ElideRight
        }
        Button {
            iconText: ""
            fontFamily: "JetBrainsMono Nerd Font"
            fontSize: Style.font.body
            Layout.preferredWidth: Style.space(28)
            onClicked: {
                if (root.hostPanel) root.hostPanel.close()
                filePicker.running = true
            }
        }
    }
    Label {
        id: importMsg
        text: "ℹ Profile already imported — connection reused"
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        color: Color.accent; opacity: 0.85; wrapMode: Text.Wrap
        visible: root.service ? root.service.importReused : false
        Layout.fillWidth: true
    }
    Timer {
        id: importMsgTimer
        interval: 3500
        onTriggered: { if (root.service) root.service.importReused = false }
    }
    Connections {
        target: root.service
        function onImportReusedChanged() { if (root.service && root.service.importReused) importMsgTimer.restart() }
    }

    // ── Connection options ──
    Label { text: "Connection"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        CheckBox {
            id: autoBox
            text: "Auto"
            font.family: Style.font.family; font.pixelSize: Style.font.body
            Layout.fillWidth: true
            onClicked: { if (root.service) root.service.setRemote("", "") }
        }
        CheckBox {
            id: udpBox
            text: "UDP (1194)"
            font.family: Style.font.family; font.pixelSize: Style.font.body
            Layout.fillWidth: true
            onClicked: { if (root.service) root.service.setRemote("1194", "udp") }
        }
        CheckBox {
            id: tcpBox
            text: "TCP (443)"
            font.family: Style.font.family; font.pixelSize: Style.font.body
            Layout.fillWidth: true
            onClicked: { if (root.service) root.service.setRemote("443", "tcp") }
        }
    }
    function syncConnChecks() {
        if (!root.service) return
        var p = root.service.remotePort, pr = root.service.remoteProto
        autoBox.checked = !p
        udpBox.checked = (p === "1194" && pr === "udp")
        tcpBox.checked = (p === "443" && pr === "tcp")
    }
    Component.onCompleted: syncConnChecks()
    Connections {
        target: root.service
        function onRemotePortChanged() { root.syncConnChecks() }
        function onRemoteProtoChanged() { root.syncConnChecks() }
    }

    CheckBox {
        id: mssfixBox
        text: "mssfix 1360 (HTTPS/MTU issues)"
        font.family: Style.font.family; font.pixelSize: Style.font.body
        Layout.fillWidth: true
        checked: root.service ? root.service.mssfixEnabled : false
        onToggled: { if (root.service) root.service.setMssfix(checked) }
    }
    CheckBox {
        id: splitBox
        text: "Split tunnel"
        font.family: Style.font.family; font.pixelSize: Style.font.body
        Layout.fillWidth: true
        checked: root.service ? root.service.splitTunnel : false
        onToggled: { if (root.service) root.service.setSplit(checked) }
    }

    // ── Credentials ──
    Label { text: "Credentials"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    TextField {
        id: userField
        Layout.fillWidth: true
        font.family: Style.font.family; font.pixelSize: Style.font.body
        text: root.service ? root.service.username : ""
        placeholderText: "Username"
        onTextChanged: {
            if (root.service) root.service.username = userField.text
        }
    }
    Label {
        text: "Password and TOTP are requested at connection time."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        opacity: 0.6; wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    // ── MFA / TOTP ──
    Label { text: "MFA / TOTP"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    CheckBox {
        id: totpBox
        text: "Require TOTP code (authenticator app)"
        font.family: Style.font.family; font.pixelSize: Style.font.body
        Layout.fillWidth: true
        checked: root.service ? root.service.totpEnabled : false
        onToggled: { if (root.service) root.service.setTotp(checked) }
    }
    Label {
        text: "At connection time, a field appears to enter the 6-digit code."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        opacity: 0.5; wrapMode: Text.Wrap; Layout.fillWidth: true
    }
    Label {
        visible: root.service ? root.service.staticChallenge : false
        text: "This profile enforces a static-challenge: the TOTP code is required."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        color: Color.urgent; wrapMode: Text.Wrap; Layout.fillWidth: true
    }
}
