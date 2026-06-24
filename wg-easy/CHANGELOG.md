# Changelog

## 1.1.0

- **Breaking change: removed Home Assistant Ingress.** wg-easy is a SPA that
  references all of its assets with absolute root paths, so it cannot operate
  behind HA Ingress (every asset returns 404). The web UI is now exposed
  directly on a TCP port of the host.
- New option `webui_port` (default `51821`) — the TCP port for the wg-easy web
  UI. Reach it at `http://<HA_IP>:<webui_port>` or behind your own HTTPS
  reverse proxy (e.g. nginx with a subdomain).
- Default `insecure` is now `true` so the login cookie works over plain HTTP for
  direct local access. Set it to `false` when serving the UI behind HTTPS.
- Removed `ingress`, `ingress_port`, `ingress_stream`, `panel_*` from the
  manifest.

## 1.0.2

- **Fix: Home Assistant Ingress now works.** The Supervisor does not pass the
  Ingress port to the add-on container, so a dynamic `ingress_port: 0` cannot
  work. Switched to a **fixed `ingress_port: 51821`** and make wg-easy listen
  on exactly that port. This resolves the "app seems to not be ready" popup
  when opening the UI from the sidebar.

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
