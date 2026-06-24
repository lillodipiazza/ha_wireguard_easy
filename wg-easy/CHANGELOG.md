# Changelog

## 1.0.1

- **Fix: switch to `iptables-nft` backend.** Home Assistant OS uses a modern
  nftables-only kernel (Linux 6.x) with no legacy `ip_tables` module, which
  made the upstream `iptables-legacy` default crash WireGuard startup with
  `Module ip_tables not found`. Now selects `iptables-nft`/`ip6tables-nft`
  (uses the in-kernel `nf_tables` subsystem).
- Enable IPv4/IPv6 forwarding at startup (best effort) so VPN clients can
  reach the LAN/internet.

## 1.0.0

- Initial release.
- Wraps upstream **wg-easy v15** (`ghcr.io/wg-easy/wg-easy:15`).
- Home Assistant **Ingress** web UI.
- **Unattended first-run setup** driven by add-on options
  (host, port, admin user/password, IPv4/IPv6 CIDR, DNS, allowed IPs).
- Persistent data: `/etc/wireguard` → `/data/wg-easy` (SQLite DB + wg0.conf).
- Host networking with `NET_ADMIN` + `SYS_MODULE` for full LAN access from VPN clients.
- Architectures: `amd64`, `aarch64`.
