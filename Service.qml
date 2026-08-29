pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string omarchyPath: ""
    property var shell: null
    property var manifest: null
    property var pluginRegistry: null

    // ── Constants ──
    readonly property int mgmtPort: 7505
    readonly property int maxHistory: 180

    // ── Connection state ──
    property bool connected: false
    property bool busy: false
    property string lastError: ""
    property double connectTime: 0
    property string uptime: "--"

    property string iface: ""
    property string vpnIp: ""
    property string gateway: ""
    property var dns: []
    property var searchDomains: []
    property var routes: []
    property string latency: "--"
    property string remote: ""
    property string link: "--"
    property string dnsCurrent: "--"
    property string dnsDomain: "--"

    // ── Traffic (bytes/s) + history for the graph ──
    property int rxBytes: 0
    property int txBytes: 0
    property real rxRate: 0
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []
    property real peakRate: 0

    // ── Profile / auth state ──
    property var profiles: []
    property string selectedProfile: ""
    readonly property string activeProfileName: {
        if (!selectedProfile || !profiles) return ""
        for (var i = 0; i < profiles.length; i++)
            if (profiles[i].path === selectedProfile) return profiles[i].name
        return ""
    }
    property string username: ""
    property string password: ""
    property bool totpEnabled: false
    property bool hasCredentials: false

    property string remoteHost: ""
    property string remotePort: ""
    property string remoteProto: ""
    property bool mssfixEnabled: false
    property bool splitTunnel: true
    property bool staticChallenge: false
    property bool importReused: false

    // ── Script path helper ──
    function scriptPath(name) {
        return Qt.resolvedUrl("bin/" + name).toString().replace(/^file:\/\//, "")
    }

    readonly property string authDir: (env_HOME !== "" ? env_HOME : (shell && shell.hasOwnProperty("home") && shell.home ? shell.home : "")) + "/.config/openvpn"
    property string env_HOME: ""

    Component.onCompleted: {
        homeProc.running = true
        loadSettings()
        refreshProfiles()
        statusProc.running = true
    }

    Process {
        id: homeProc
        command: ["bash", "-lc", "echo -n $HOME"]
        stdout: StdioCollector { waitForEnd: true }
        onExited: function() {
            env_HOME = stdout.text.trim()
        }
    }

    // ── Settings (non-secret) ──
    Process {
        id: settingsProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            try {
                var o = JSON.parse(stdout.text.trim())
                root.selectedProfile = o.profile || ""
                root.username = o.user || ""
                root.totpEnabled = o.totp === true
                root.remotePort = o.port || ""
                root.remoteProto = o.proto || ""
                root.mssfixEnabled = o.mssfix === true
                root.splitTunnel = o.split !== false
                root.hasCredentials = root.username.length > 0
                if (root.selectedProfile) {
                    root.detectStaticChallenge()
                    root.parseRemote()
                }
            } catch (e) {}
        }
    }
    function loadSettings() {
        settingsProc.command = ["bash", root.scriptPath("omarchy-openvpn-config"), "get"]
        settingsProc.running = true
    }
    Process {
        id: setProfileProc
        function run(path) {
            command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-profile", path]
            running = true
        }
    }
    Process {
        id: setTotpProc
        function run(on) {
            command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-totp", on ? "1" : "0"]
            running = true
        }
    }
    Process {
        id: setRemoteProc
        function run(port, proto) {
            command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-remote", port, proto]
            running = true
        }
    }
    Process {
        id: setMssfixProc
        function run(on) {
            command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-mssfix", on ? "1" : "0"]
            running = true
        }
    }
    Process {
        id: setSplitProc
        function run(on) {
            command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-split", on ? "1" : "0"]
            running = true
        }
    }
    function saveSettings() {
        setProfileProc.run(root.selectedProfile)
        setTotpProc.run(root.totpEnabled)
        setRemoteProc.run(root.remotePort, root.remoteProto)
        setMssfixProc.run(root.mssfixEnabled)
        setSplitProc.run(root.splitTunnel)
    }

    // ── Static-challenge (TOTP) detection ──
    Process {
        id: scProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            var sc = stdout.text.trim() === "1"
            root.staticChallenge = sc
            if (sc && !root.totpEnabled) {
                root.totpEnabled = true
                setTotpProc.run(true)
            }
        }
    }
    function detectStaticChallenge() {
        if (!root.selectedProfile) { root.staticChallenge = false; return }
        scProc.command = ["bash", root.scriptPath("omarchy-openvpn-static-challenge"), root.selectedProfile]
        scProc.running = true
    }

    // ── Default remote (host/port/proto) from the profile ──
    Process {
        id: remoteProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            var parts = stdout.text.trim().split(/\s+/)
            if (parts.length >= 1 && parts[0]) root.remoteHost = parts[0]
            if (parts.length >= 3) {
                if (!root.remotePort) root.remotePort = parts[1]
                if (!root.remoteProto) root.remoteProto = parts[2]
            }
        }
    }
    function parseRemote() {
        if (!root.selectedProfile) { root.remoteHost = ""; return }
        remoteProc.command = ["bash", root.scriptPath("omarchy-openvpn-remote"), root.selectedProfile]
        remoteProc.running = true
    }

    // ── Profile list ──
    Process {
        id: profilesProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            try {
                root.profiles = JSON.parse(stdout.text.trim())
                if (!root.selectedProfile && root.profiles.length > 0)
                    root.selectProfile(root.profiles[0].path)
            } catch (e) {
                root.profiles = []
            }
        }
    }
    function refreshProfiles() {
        profilesProc.command = ["python3", root.scriptPath("omarchy-openvpn-profiles")]
        profilesProc.running = true
    }

    // ── Status polling ──
    Process {
        id: statusProc
        command: ["python3", root.scriptPath("omarchy-openvpn-status")]
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            if (code !== 0) { root.connected = false; return }
            try {
                var o = JSON.parse(stdout.text.trim())
                var wasConnected = root.connected
                root.connected = o.connected === true
                // iface / link / vpnIp are owned by infoProc (it detects the
                // real tunnel device); do not overwrite them here.
                if (root.connected && !wasConnected) {
                    root.rxHistory = []
                    root.txHistory = []
                    root.rxRate = 0
                    root.txRate = 0
                    root.peakRate = 0
                    _lastRx = 0; _lastTx = 0; _lastTs = 0
                    root.connectTime = Date.now()
                }
                if (!root.connected) {
                    root.connectTime = 0
                    root.uptime = "--"
                    root.iface = ""
                    root.link = "--"
                    root.vpnIp = "--"
                    root.gateway = ""
                    root.dns = []
                    root.searchDomains = []
                    root.routes = []
                    root.latency = "--"
                    root.remote = ""
                    root.dnsCurrent = "--"
                    root.dnsDomain = "--"
                }
                if (root.connected && !infoProc.running)
                    infoProc.running = true
            } catch (e) {
                root.connected = false
            }
        }
    }

    // ── Network info + traffic counters ──
    Process {
        id: infoProc
        command: ["python3", root.scriptPath("omarchy-openvpn-info")]
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            if (code !== 0) return
            try {
                var o = JSON.parse(stdout.text.trim())
                root.gateway = o.gateway || ""
                root.dns = o.dns || []
                root.searchDomains = o.search || []
                root.routes = o.routes || []
                root.latency = o.latency || "--"
                root.remote = o.remote || ""
                if (o.iface) root.iface = o.iface
                root.link = o.link || "--"
                root.dnsCurrent = o.dnsCurrent || "--"
                root.dnsDomain = o.dnsDomain || "--"
                root.vpnIp = o.ip || "--"

                // Traffic rate from cumulative counters
                var rx = Number(o.rx) || 0
                var tx = Number(o.tx) || 0
                var now = Date.now()
                if (_lastTs > 0 && now > _lastTs) {
                    var dt = (now - _lastTs) / 1000
                    var rRate = (rx - _lastRx) / dt
                    var tRate = (tx - _lastTx) / dt
                    if (rRate < 0) rRate = 0
                    if (tRate < 0) tRate = 0
                    root.rxRate = rRate
                    root.txRate = tRate
                    var nh = root.rxHistory.concat([{ time: now, value: rRate }])
                    var th = root.txHistory.concat([{ time: now, value: tRate }])
                    if (nh.length > root.maxHistory) nh = nh.slice(nh.length - root.maxHistory)
                    if (th.length > root.maxHistory) th = th.slice(th.length - root.maxHistory)
                    root.rxHistory = nh
                    root.txHistory = th
                    var peak = 0
                    for (var i = 0; i < nh.length; i++) if (nh[i].value > peak) peak = nh[i].value
                    for (var j = 0; j < th.length; j++) if (th[j].value > peak) peak = th[j].value
                    root.peakRate = peak
                }
                _lastRx = rx
                _lastTx = tx
                _lastTs = now
            } catch (e) {}
        }
    }

    property real _lastRx: 0
    property real _lastTx: 0
    property real _lastTs: 0

    // ── Uptime ticker ──
    Timer {
        id: uptimeTimer
        interval: 1000
        repeat: true
        running: root.connected
        onTriggered: {
            if (root.connectTime > 0) {
                var s = Math.floor((Date.now() - root.connectTime) / 1000)
                var h = Math.floor(s / 3600)
                var m = Math.floor((s % 3600) / 60)
                var sec = s % 60
                var parts = []
                if (h > 0) parts.push(h + "h")
                if (m > 0 || h > 0) parts.push(m + "m")
                parts.push(sec + "s")
                root.uptime = parts.join(" ")
            }
        }
    }

    // ── Connect (NetworkManager / nmcli, no sudo, secrets via env) ──
    Process {
        id: connectProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            root.busy = false
            var out = stdout.text.trim()
            if (out.indexOf("SUCCESS") === 0) {
                root.lastError = ""
                Qt.callLater(function() { statusProc.running = true })
            } else {
                root.lastError = out.indexOf("FAIL") === 0 ? out.substring(5).trim() : "Connection failed"
                Qt.callLater(function() { statusProc.running = true })
            }
        }
    }
    property string _pendingOtp: ""

    // ── Disconnect (NetworkManager / nmcli, no sudo) ──
    Process {
        id: disconnectProc
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            root.busy = false
            root.rxHistory = []
            root.txHistory = []
            root.rxRate = 0
            root.txRate = 0
            root.peakRate = 0
            Qt.callLater(function() { statusProc.running = true })
        }
    }

    function vpnConnect(user, pass, otp) {
        if (root.busy || root.connected) return
        if (!root.selectedProfile) { root.lastError = "No profile selected"; return }
        if (!user || !pass) { root.lastError = "Identifiants manquants"; return }
        root.busy = true
        root.lastError = ""
        _pendingOtp = otp || ""
        connectProc.environment = {
            "OPENVPN_USER": user,
            "OPENVPN_PASSWORD": pass,
            "OPENVPN_OTP": _pendingOtp,
            "PATH": "/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        }
        connectProc.command = ["bash", root.scriptPath("omarchy-openvpn-connect"),
            root.selectedProfile, root.remotePort, root.remoteProto,
            root.mssfixEnabled ? "1" : "0", root.splitTunnel ? "1" : "0"]
        connectProc.running = true
    }

    function vpnDisconnect() {
        root.busy = true
        disconnectProc.command = ["bash", root.scriptPath("omarchy-openvpn-disconnect"), root.selectedProfile]
        disconnectProc.running = true
    }

    function toggleVpn(otp) {
        if (root.connected) vpnDisconnect()
        else vpnConnect(root.username, root.password, otp)
    }

    // ── UI actions ──
    function selectProfile(path) {
        root.selectedProfile = path
        saveSettings()
        detectStaticChallenge()
        parseRemote()
    }
    function setTotp(on) {
        root.totpEnabled = on
        saveSettings()
    }
    function setRemote(port, proto) {
        root.remotePort = port
        root.remoteProto = proto
        saveSettings()
    }
    function setSplit(on) {
        root.splitTunnel = on
        saveSettings()
    }
    // Only the username is persisted; the password is never written to disk
    // (it is passed at connect time via the process environment).
    function saveCredentials(user, pass) {
        root.username = user
        credWrite.command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-user", user]
        credWrite.running = true
    }
    Process {
        id: credWrite
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) { root.hasCredentials = root.username.length > 0 }
    }
    onUsernameChanged: { if (root.username) usernameSaveTimer.restart() }
    Timer {
        id: usernameSaveTimer
        interval: 400
        repeat: false
        onTriggered: {
            credWrite.command = ["bash", root.scriptPath("omarchy-openvpn-config"), "set-user", root.username]
            credWrite.running = true
        }
    }
    function importProfile(src) {
        root.importReused = false
        importRun.command = ["bash", root.scriptPath("omarchy-openvpn-import"), src]
        importRun.running = true
    }
    Process {
        id: importRun
        stdout: StdioCollector { waitForEnd: true }
        onExited: function(code) {
            refreshProfiles()
            var out = stdout.text.trim()
            if (out.indexOf("EXISTS:") === 0) {
                root.importReused = true
                out = out.substring(6)
            }
            if (code === 0 && out) {
                root.selectProfile(out)
            }
        }
    }

    // ── Periodic poll ──
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true
            if (root.connected && !infoProc.running) infoProc.running = true
        }
    }

    // ── Busy watchdog: never hang on "Connexion en cours…" ──
    Timer {
        id: busyWatchdog
        interval: 40000
        running: root.busy
        repeat: false
        onTriggered: {
            if (!root.connected) {
                root.busy = false
                root.lastError = "Timeout — check the TOTP code or the polkit authentication prompt"
            }
        }
    }
}
