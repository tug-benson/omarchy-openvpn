pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "OpenVPN Connect"
    manageIpc: false

    property var hostWidget: null
    property var anchorItem: null
    property bool showConfig: false
    property bool totpPrompt: false
    property bool passPrompt: false
    property string pendingPassword: ""
    readonly property string icon: "󰯄"

    function toggleVpnFlow() {
        if (root.isConnected) { if (root.service) root.service.vpnDisconnect(); return }
        if (!root.service) return
        if (!root.hasCreds) { root.showConfig = true; return }
        root.passPrompt = true
    }

    // ── Theme tokens ──
    readonly property string fontFam: Style.font.family
    readonly property int titleSize: Style.font.title
    readonly property int logoSize: titleSize + 7
    readonly property int bodySize: Style.font.body
    readonly property int captionSize: Style.font.caption
    readonly property color fg: Color.foreground
    readonly property color cAccent: Color.accent
    readonly property color cDown: Color.muted
    readonly property color cOk: Color.accent
    readonly property color cErr: Color.urgent
    readonly property color cWarn: Color.urgent
    readonly property color cMuted: Color.muted

    readonly property var service: hostWidget && hostWidget.service
        ? hostWidget.service
        : (bar && bar.shell && typeof bar.shell.serviceFor === "function"
           ? (bar.shell.serviceFor("io.github.tug-benson.openvpn") || bar.shell.serviceFor("openvpn")) : null)

    readonly property bool isConnected: service ? service.connected : false
    readonly property bool isBusy: service ? service.busy : false
    readonly property bool totp: service ? (service.totpEnabled || service.staticChallenge) : false
    readonly property bool hasCreds: service ? service.hasCredentials : false

    function fmtRate(bps) {
        if (!bps || bps <= 0) return "0 B/s"
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + " KB/s"
        if (bps < 1073741824) return (bps / 1048576).toFixed(2) + " MB/s"
        return (bps / 1073741824).toFixed(2) + " GB/s"
    }
    function join(arr) {
        if (!arr || arr.length === 0) return "--"
        return arr.join(", ")
    }

    // ── Detail popover (2×2 buttons) ──
    property string detailField: ""
    property string detailTitle: ""
    property string detailContent: ""
    function showDetail(field) {
        root.detailField = field
        if (field === "dns") { root.detailTitle = "DNS"; root.detailContent = join(service ? service.dns : []) }
        else if (field === "dnsDomain") { root.detailTitle = "DNS Domain"; root.detailContent = service ? (service.dnsDomain || "--") : "--" }
        else if (field === "gateway") { root.detailTitle = "Gateway"; root.detailContent = service ? (service.gateway || "--") : "--" }
        else if (field === "routes") { root.detailTitle = "Routes"; root.detailContent = join(service ? service.routes : []) }
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: Style.space(340)
        contentHeight: root.totpPrompt
            ? (cardCol.implicitHeight + Style.space(40))
            : (flick.contentHeight + Style.space(36))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: col.implicitHeight
                clip: true
                ColumnLayout {
                    id: col
                    width: flick.width - Style.space(16)
                    x: Style.space(8)
                    spacing: Style.space(6)
                    visible: !root.totpPrompt

                // ── Title + settings ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    Layout.alignment: Qt.AlignVCenter
                    Label {
            textFormat: Text.PlainText;
                        text: root.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: logoSize
                        color: cAccent
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Label {
            textFormat: Text.PlainText;
                        text: "OpenVPN"
                        font.family: fontFam
                        font.pixelSize: titleSize + 1
                        font.bold: true
                        color: cMuted
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Button {
                        iconText: ""
                        fontFamily: "JetBrainsMono Nerd Font"
                        fontSize: Style.font.body
                        tooltipText: "Settings"
                        Layout.preferredWidth: Style.space(28)
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.showConfig = !root.showConfig
                    }
                }

                // ── Connect / Disconnect toggle ──
                Toggle {
                    label: isConnected ? "Connected" : "Disconnected"
                    description: isBusy ? "Connecting…" : ""
                    checked: isConnected
                    enabled: !isBusy && service !== null
                    Layout.fillWidth: true
                    onClicked: root.toggleVpnFlow()
                }

                // ── Status / error line ──
                Label {
            textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    font.family: fontFam
                    font.pixelSize: captionSize
                    opacity: 0.8
                    color: (service && service.lastError) ? cErr
                          : isConnected ? cOk
                          : (isBusy ? cWarn : cMuted)
                    text: isBusy ? "Connecting…"
                         : (service && service.lastError) ? service.lastError
                         : isConnected ? "Connected"
                         : (hasCreds ? "Disconnected" : "Username required")
                }

                // ── Tunnel interface (shown above the graph, right aligned) ──
                RowLayout {
                    Layout.fillWidth: true
                    visible: isConnected && service && service.iface
                    Label {
            textFormat: Text.PlainText;
                        text: "Tunnel"
                        font.family: fontFam
                        font.pixelSize: captionSize
                        color: Color.foreground
                        opacity: 0.6
                    }
                    Label {
            textFormat: Text.PlainText;
                        text: service ? (service.iface + (service.link && service.link !== "--" ? " (Link " + service.link + ")" : "")) : ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: captionSize
                        color: cAccent
                        Layout.alignment: Qt.AlignRight
                    }
                }

                // ── Traffic graph (always shown; flat when disconnected) ──
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Style.space(64)
                    Sparkline {
                        anchors.fill: parent
                        points: service ? service.txHistory : []
                        mirrorPoints: service ? service.rxHistory : []
                        lineColor: cAccent
                        mirrorLineColor: cDown
                        gridColor: Qt.rgba(1, 1, 1, 0.08)
                        fixedMaximum: service && service.peakRate > 0 ? service.peakRate : 1
                    }
                    RowLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Style.space(6)
                        Label {
            textFormat: Text.PlainText;
                            text: "↑ " + fmtRate(service ? service.txRate : 0)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: captionSize
                            color: cAccent
                        }
                        Label {
            textFormat: Text.PlainText;
                            text: "↓ " + fmtRate(service ? service.rxRate : 0)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: captionSize
                            color: cDown
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                // ── Separator ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // ── Connection info (only when connected) ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(4)
                    visible: isConnected

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Interface:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: service ? ((service.iface || "--") + (service.link && service.link !== "--" ? " (Link " + service.link + ")" : "")) : "--" }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Tunnel IP:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: service ? (service.vpnIp || "--") : "--" }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Current DNS:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: service ? (service.dnsCurrent || "--") : "--" }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "DNS:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: join(service ? service.dns : []) }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Remote:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: service ? (service.remote || "--") : "--" }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Latency:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: (service ? (service.latency || "--") : "--") + " ms" }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label {
            textFormat: Text.PlainText; text: "Uptime:"; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; opacity: 0.6 }
                        Label {
            textFormat: Text.PlainText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; font.family: fontFam; font.pixelSize: bodySize; color: Color.foreground; elide: Text.ElideLeft; text: service ? (service.uptime || "--") : "--" }
                    }

                    // Complex fields — 2×2 buttons opening a detail panel
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(6)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(6)
                            QQC.Button {
                                text: "DNS"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                onClicked: root.showDetail("dns")
                                background: Rectangle {
                                    color: Color.background
                                    border.color: cAccent
                                    border.width: 1
                                    radius: Style.space(4)
                                }
                            }
                            QQC.Button {
                                text: "DNS Domain"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                onClicked: root.showDetail("dnsDomain")
                                background: Rectangle {
                                    color: Color.background
                                    border.color: cAccent
                                    border.width: 1
                                    radius: Style.space(4)
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(6)
                            QQC.Button {
                                text: "Gateway"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                onClicked: root.showDetail("gateway")
                                background: Rectangle {
                                    color: Color.background
                                    border.color: cAccent
                                    border.width: 1
                                    radius: Style.space(4)
                                }
                            }
                            QQC.Button {
                                text: "Routes"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                onClicked: root.showDetail("routes")
                                background: Rectangle {
                                    color: Color.background
                                    border.color: cAccent
                                    border.width: 1
                                    radius: Style.space(4)
                                }
                            }
                        }
                    }
                }

                // ── Config panel (toggled) — always available, even when disconnected ──
                Loader {
                    id: configLoader
                    Layout.fillWidth: true
                    active: root.showConfig
                    visible: root.showConfig
                    source: Qt.resolvedUrl("ConfigPanel.qml")
                    onLoaded: {
                        if (item && "service" in item) item.service = root.service
                        if (item && "hostPanel" in item) item.hostPanel = root
                        if (item && item.service && item.service.refreshProfiles) item.service.refreshProfiles()
                    }
                }
            }
            }

            // ── TOTP prompt overlay (standalone compact card) ──
            Item {
                anchors.fill: parent
                visible: totpPrompt
                onVisibleChanged: if (visible) { otpField.text = ""; otpField.forceActiveFocus() }

                Rectangle {
                    anchors.fill: parent
                    color: Util.alpha(Color.background, 0.85)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Style.space(24), Style.space(260))
                    implicitHeight: cardCol.implicitHeight + Style.space(24)
                    radius: Style.space(8)
                    color: Color.background
                    border.color: cAccent
                    border.width: 1

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: Style.space(12)
                        spacing: Style.space(8)

                        Label {
            textFormat: Text.PlainText;
                            text: "Two-factor authentication"
                            font.family: fontFam
                            font.pixelSize: bodySize
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        Label {
            textFormat: Text.PlainText;
                            text: "6-digit TOTP code"
                            font.family: fontFam
                            font.pixelSize: captionSize
                            opacity: 0.7
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: otpField
                            Layout.fillWidth: true
                            font.family: fontFam
                            font.pixelSize: bodySize
                            maximumLength: 6
                            inputMethodHints: Qt.ImhDigitsOnly
                            placeholderText: "123456"
                            horizontalAlignment: Text.AlignHCenter
                            onAccepted: otpOk.clicked()
                            onVisibleChanged: if (visible) forceActiveFocus()
                        }
                        RowLayout {
                            spacing: Style.space(8)
                            Button {
                                text: "Cancel"
                                fontSize: captionSize
                                Layout.fillWidth: true
                                onClicked: root.totpPrompt = false
                            }
                            Button {
                                id: otpOk
                                text: "Validate"
                                fontSize: captionSize
                                Layout.fillWidth: true
                                enabled: otpField.text.length === 6
                                onClicked: {
                                    var c = otpField.text.trim()
                                    root.totpPrompt = false
                                    if (service) service.vpnConnect(service.username, root.pendingPassword, c)
                                }
                            }
                        }
                    }
                }
            }

            // ── Password prompt overlay (standalone compact card) ──
            Item {
                anchors.fill: parent
                visible: passPrompt
                onVisibleChanged: if (visible) { passField.text = ""; passField.forceActiveFocus() }

                Rectangle {
                    anchors.fill: parent
                    color: Util.alpha(Color.background, 0.85)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Style.space(24), Style.space(260))
                    implicitHeight: passCol.implicitHeight + Style.space(24)
                    radius: Style.space(8)
                    color: Color.background
                    border.color: cAccent
                    border.width: 1

                    ColumnLayout {
                        id: passCol
                        anchors.fill: parent
                        anchors.margins: Style.space(12)
                        spacing: Style.space(8)

                        Label {
            textFormat: Text.PlainText;
                            text: "Password"
                            font.family: fontFam
                            font.pixelSize: bodySize
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: passField
                            Layout.fillWidth: true
                            font.family: fontFam
                            font.pixelSize: bodySize
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            horizontalAlignment: Text.AlignHCenter
                            onAccepted: passOk.clicked()
                            onVisibleChanged: if (visible) forceActiveFocus()
                        }
                        RowLayout {
                            spacing: Style.space(8)
                            Button {
                                text: "Cancel"
                                fontSize: captionSize
                                Layout.fillWidth: true
                                onClicked: root.passPrompt = false
                            }
                            Button {
                                id: passOk
                                text: "Validate"
                                fontSize: captionSize
                                Layout.fillWidth: true
                                enabled: passField.text.length > 0
                                onClicked: {
                                    var p = passField.text
                                    root.passPrompt = false
                                    root.pendingPassword = p
                                    if (root.totp) root.totpPrompt = true
                                    else if (service) service.vpnConnect(service.username, root.pendingPassword, "")
                                }
                            }
                        }
                    }
                }
            }

            // ── Detail popover (2×2 buttons) ──
            Item {
                anchors.fill: parent
                z: 100
                visible: root.detailField !== ""
                onVisibleChanged: if (visible) detailClose.forceActiveFocus()

                Rectangle {
                    anchors.fill: parent
                    color: Util.alpha(Color.background, 0.85)
                    MouseArea { anchors.fill: parent; onClicked: root.detailField = "" }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - Style.space(24)
                    height: Math.min(parent.height - Style.space(40), Math.max(detCol.implicitHeight + Style.space(24), Style.space(180)))
                    radius: Style.space(8)
                    color: Color.background
                    border.color: cAccent
                    border.width: 1

                    ColumnLayout {
                        id: detCol
                        anchors.fill: parent
                        anchors.margins: Style.space(12)
                        spacing: Style.space(8)

                        Label {
            textFormat: Text.PlainText;
                            text: root.detailTitle
                            font.family: fontFam
                            font.pixelSize: bodySize
                            font.bold: true
                            color: Color.foreground
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: Style.space(100)
                            contentWidth: width
                            contentHeight: detText.implicitHeight
                            clip: true
                            Text {
            textFormat: Text.PlainText;
                                id: detText
                                width: parent.width
                                text: root.detailContent
                                font.family: fontFam
                                font.pixelSize: bodySize
                                color: Color.foreground
                                wrapMode: Text.Wrap
                            }
                        }

                        Button {
                            id: detailClose
                            text: "Close"
                            fontSize: captionSize
                            Layout.fillWidth: true
                            onClicked: root.detailField = ""
                        }
                    }
                }
            }
        }
    }
}
