# Marketplace submission (draft)

Ready-to-paste text for the omarchy-plugin-marketplace "Submit a plugin" issue
(https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml).
The submission platform is currently closed; keep this until it reopens, then paste
the block below (and ensure `preview.png` is committed at the repo root).

---

### Repository URL

https://github.com/tug-benson/omarchy-openvpn

### Category

System

### Tags

security, quickshell, bar

### Suggest a missing tag

*No response*

### Maintainer notes

Omarchy OpenVPN Connect manages an OpenVPN connection from the Omarchy bar: import
multiple `.ovpn` profiles, authenticate with username/password + TOTP (MFA) via
challenge/response, view a live traffic graph, and inspect a network info panel
(tunnel IP, gateway, DNS, routes, search domains). Compatible with OpenVPN Access
Server (AS).

- Kind: bar-widget + service (`BarWidget.qml` / `Panel.qml` / `Service.qml`)
- License: MIT (root `LICENSE` file)
- External dependencies: `networkmanager`, `openvpn` (>= 2.6), `python3`, `polkit`,
  `zenity` — installable with `sudo pacman -S networkmanager openvpn python3 polkit zenity`.
  The plugin installs nothing on its own; it drives NetworkManager via `nmcli` using the
  user's existing PolicyKit privileges (no `sudo` / NOPASSWD).
- Install: `omarchy plugin add https://github.com/tug-benson/omarchy-openvpn`
- Remove: `omarchy plugin remove openvpn`
- Permissions / privacy: the password and TOTP code are entered at connect time and
  passed only through the process environment to `nmcli`; they are never written to disk.
  Only the non-secret username is persisted (to `~/.config/openvpn/ui.json`). The plugin
  does not modify system configuration beyond creating the NetworkManager connection for
  the imported profile.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.

---
