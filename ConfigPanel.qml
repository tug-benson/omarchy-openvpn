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
        command: ["zenity", "--file-selection", "--title=Select a .ovpn file", "--file-filter=OpenVPN | *.ovpn *.OVPN", "--file-filter=All files | *"]
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
    Label {
            textFormat: Text.PlainText; text: "Profile"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Label {
            textFormat: Text.PlainText;
            Layout.fillWidth: true
            text: (root.service && root.service.activeProfileName) ? root.service.activeProfileName : "—"
            font.family: Style.font.family; font.pixelSize: Style.font.body
            color: Color.foreground
            elide: Text.ElideRight
        }
        Button {
            visible: root.service ? root.service.profiles.length > 1 : false
            text: "Change"
            tooltipText: "Pick another OpenVPN profile"
            fontSize: Style.font.caption
            onClicked: {
                if (root.service) root.service.refreshProfiles()
                root.showProfiles = !root.showProfiles
            }
        }
        Button {
            iconText: ""
            fontFamily: "JetBrainsMono Nerd Font"
            fontSize: Style.font.body
            Layout.preferredWidth: Style.space(28)
            onClicked: {
                if (root.hostPanel) root.hostPanel.close()
                filePicker.running = true
            }
        }
    }

    // ── Profile picker: one row per imported OpenVPN connection ──
    // Lists the connections reported by omarchy-openvpn-profiles; picking one
    // runs Service.selectProfile(), which persists the choice and refreshes the
    // settings that depend on it (challenge detection, remote host/port).
    property bool showProfiles: false
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(2)
        visible: root.showProfiles && root.service && root.service.profiles.length > 1
        Repeater {
            model: root.service ? root.service.profiles : []
            delegate: Button {
                required property var modelData
                Layout.fillWidth: true
                leftAlign: true
                fontSize: Style.font.body
                text: modelData.name
                selected: root.service && root.service.selectedProfile === modelData.path
                onClicked: {
                    if (root.service) root.service.selectProfile(modelData.path)
                    root.showProfiles = false
                }
            }
        }
    }
    Label {
            textFormat: Text.PlainText;
        id: importMsg
        text: "ℹ Profile already imported — connection reused"
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        color: Color.accent; opacity: 0.85; wrapMode: Text.Wrap
        visible: root.service ? root.service.importReused : false
        Layout.fillWidth: true
    }
    Label {
            textFormat: Text.PlainText;
        id: importErr
        text: (root.service && root.service.importError) ? root.service.importError : ""
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        color: Color.urgent; wrapMode: Text.Wrap
        visible: text !== ""
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
    Label {
            textFormat: Text.PlainText; text: "Connection"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
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
    Label {
            textFormat: Text.PlainText; text: "Credentials"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
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
            textFormat: Text.PlainText;
        text: "Password and TOTP are requested at connection time."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        opacity: 0.6; wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    // ── MFA / TOTP ──
    Label {
            textFormat: Text.PlainText; text: "MFA / TOTP"; font.family: Style.font.family; font.pixelSize: Style.font.body; font.bold: true; opacity: 0.7 }
    CheckBox {
        id: totpBox
        text: "Require TOTP code (authenticator app)"
        font.family: Style.font.family; font.pixelSize: Style.font.body
        Layout.fillWidth: true
        checked: root.service ? root.service.totpEnabled : false
        onToggled: { if (root.service) root.service.setTotp(checked) }
    }
    Label {
            textFormat: Text.PlainText;
        text: "At connection time, a field appears to enter the 6-digit code."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        opacity: 0.5; wrapMode: Text.Wrap; Layout.fillWidth: true
    }
    Label {
            textFormat: Text.PlainText;
        visible: root.service ? root.service.staticChallenge : false
        text: "This profile enforces a static-challenge: the TOTP code is required."
        font.family: Style.font.family; font.pixelSize: Style.font.caption
        color: Color.urgent; wrapMode: Text.Wrap; Layout.fillWidth: true
    }
}
