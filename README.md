# OpenVPN Plugin for Omarchy

A plugin for Omarchy to easily manage OpenVPN connections.

## Features
- **Status Display**: Shows VPN connection status with icons.
- **Import OVPN Files**: Import configuration files easily.
- **Credential Management**: Secure login/password entry.
- **DNS & Domain Configuration**: Force DNS IP and search domain.
- **TOTP Support**: Secure entry for time-based one-time passwords.

## Installation

### Add Plugin
```bash
omarchy plugin add https://github.com/tug-benson/omarchy-openvpn.git
```

### Enable Plugin
```bash
omarchy plugin enable openvpn.client
```

## Usage
- **Status Bar**: Shows connection status with icons.
- **Context Menu**: Configure and manage VPN settings.

## Configuration Steps
1. **Import an OVPN file** via the context menu.
2. **Enter login, password** and TOTP if required.
3. **Configure DNS and domain** settings.
4. Click **Apply** to save changes.

## Project Structure
```
omarchy-openvpn/
├── manifest.json
├── shell/
│   └── plugins/
│       └── panels/
│           └── openvpn/
│               ├── Panel.qml
│               ├── ConfigPanel.qml
│               ├── TotpDialog.qml
│               ├── vpn-up.png
│               └── vpn-down-light.png
└── bin/
    ├── vpn-start
    ├── vpn-stop
    ├── vpn-status
    ├── vpn-import
    ├── vpn-apply-credentials
    ├── vpn-apply-dns
    ├── vpn-show-totp-dialog
    └── vpn-validate-totp
```

## License
MIT
