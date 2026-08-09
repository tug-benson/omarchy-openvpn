import QtQuick 2.15
import QtQuick.Controls 2.15
import Omarchy 1.0

Component {
    id: serviceComponent

    Omarchy.Service {
        id: vpnService
        name: "OpenVPN"
        description: "Service OpenVPN"

        property bool isRunning: false

        function start() {
            Omarchy.runScript("vpn-start")
            isRunning = Omarchy.runScript("vpn-status") === "running"
        }

        function showTotpDialog() {
            Omarchy.runScript("vpn-show-totp-dialog")
        }

        function stop() {
            Omarchy.runScript("vpn-stop")
            isRunning = Omarchy.runScript("vpn-status") !== "running"
        }

        function status() {
            return Omarchy.runScript("vpn-status")
        }

        function importConfig(filePath) {
            Omarchy.runScript("vpn-import", [filePath])
        }

        function applyCredentials(login, password) {
            Omarchy.runScript("vpn-apply-credentials", [login, password])
        }

        onRunningChanged: {
            console.log("OpenVPN is " + (isRunning ? "running" : "stopped"))
        }
    }
}
