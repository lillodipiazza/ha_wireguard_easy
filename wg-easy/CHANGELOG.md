# Changelog

## 1.0.0

- Initial release.
- Wraps upstream **wg-easy v15** (`ghcr.io/wg-easy/wg-easy:15`).
- Home Assistant **Ingress** web UI.
- **Unattended first-run setup** driven by add-on options
  (host, port, admin user/password, IPv4/IPv6 CIDR, DNS, allowed IPs).
- Persistent data: `/etc/wireguard` → `/data/wg-easy` (SQLite DB + wg0.conf).
- Host networking with `NET_ADMIN` + `SYS_MODULE` for full LAN access from VPN clients.
- Architectures: `amd64`, `aarch64`.
