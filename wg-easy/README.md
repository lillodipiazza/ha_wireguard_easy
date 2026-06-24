# wg-easy — Home Assistant Add-on

[![Upstream](https://img.shields.io/badge/wg--easy-v15-blue)](https://github.com/wg-easy/wg-easy)

Run a full **WireGuard VPN** with a polished **web UI** ([wg-easy](https://github.com/wg-easy/wg-easy)) directly inside Home Assistant, with **Ingress** integration, persistent configuration and an unattended first-run setup.

> ⚠️ This is an unofficial community add-on that wraps the official `ghcr.io/wg-easy/wg-easy` image. It is not affiliated with the wg-easy project.

---

## ✨ Features

- 🌐 **WireGuard VPN** with a web admin UI
- 🔗 **Home Assistant Ingress** — the UI lives in your HA sidebar
- 🧰 **Unattended setup** — the first run is auto-configured from the add-on options (admin user, endpoint, CIDR, DNS…)
- 💾 **Persistent data** — configuration & database survive add-on rebuilds/updates
- 🖥️ **Host networking** — VPN clients can reach the whole home network
- 🏗️ Multi-arch: **amd64** and **aarch64**

---

## 📦 Install

### Option A — Local add-on (no GitHub needed)

1. Copy the `wg-easy/` folder into your Home Assistant add-ons path
   (e.g. via the **Samba**/**SFTP** add-on under `/addons/wg-easy/`).
2. In HA go to **Settings → Add-ons → Add-on Store → ⋮ → Reload**.
3. The **wg-easy** card appears — open it and click **Install**.

### Option B — Add-on repository (if you push this to GitHub)

1. In HA go to **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Add the URL of your Git repository containing this folder, then **Reload**.
3. Install the **wg-easy** add-on.

> Home Assistant builds the add-on image on the fly from the included `Dockerfile`.

---

## ⚙️ Configuration

Open the add-on **Configuration** tab and set at least:

| Option | Required | Example | Notes |
|---|---|---|---|
| `host` | ✅ recommended | `vpn.example.com` | Public IP/domain clients connect to. If empty, set it later from the UI. |
| `port` | ✅ | `51820` | UDP port. **Forward this UDP port** on your router to Home Assistant. |
| `username` | ✅ | `admin` | Admin username (first run only). |
| `password` | ✅ | `Sup3r!Secret` | Admin password (first run only). Choose a strong one. |
| `address` | optional | `10.8.0.0/24` | IPv4 CIDR. |
| `ipv6_address` | optional | `fdcc:ad94:bacf:61a3::/64` | IPv6 CIDR (set together with IPv4). |
| `dns` | optional | `1.1.1.1, 1.0.0.1` | DNS for clients. |
| `allowed_ips` | optional | `0.0.0.0/0, ::/0` | Traffic routed through the VPN. |
| `disable_ipv6` | optional | `false` | Disable IPv6. |
| `insecure` | optional | `false` | Allow HTTP access to the UI. |

### ⚠️ These options are applied **only on the first run**

In wg-easy v15 all settings live in a **database**. The add-on options seed that
database on first start (wg-easy *"unattended setup"*). After that, change host,
password, DNS, etc. **from the wg-easy UI** (via Ingress). Editing the add-on
options later will not overwrite an already-configured instance.

---

## 🚀 Usage

1. **Configure** the add-on (see above) and **Save**.
2. Make sure your router **forwards UDP `port`** (default `51820`) to the Home Assistant IP.
3. **Start** the add-on.
4. Open the web UI through **Ingress** (the *Open Web UI* button or the sidebar icon).
5. Log in with the `username`/`password` you configured.
6. Create a client, scan the QR code / download the config on your device, and connect. 🎉

---

## 🧠 How it works

- The image is built `FROM ghcr.io/wg-easy/wg-easy:15` and adds `jq` + a small
  entrypoint.
- On start the entrypoint **symlinks `/etc/wireguard` → `/data/wg-easy`** so the
  SQLite database (`wg-easy.db`) and `wg0.conf` are stored on the persistent
  HA volume.
- The add-on options are mapped to wg-easy's `INIT_*` environment variables
  (first-run setup) and the web UI is bound to the Home Assistant `INGRESS_PORT`.
- Runs with **host networking** + `NET_ADMIN`/`SYS_MODULE` so WireGuard can
  create its interface and NAT rules on the host, letting VPN clients reach the
  LAN.

---

## 🔧 Troubleshooting

- **Clients can't connect / handshake fails**
  - Check the router forwards **UDP** `51820` to the HA IP.
  - Make sure `host` (public endpoint) is correct and reachable from the internet.
  - Confirm HA's public IP matches `host` (or use a dynamic DNS).
- **`Operation not permitted` / interface errors in the log**
  - The add-on needs `NET_ADMIN` + `SYS_MODULE`; these are already enabled.
  - Some HA OS versions need a reboot after first install of a privileged add-on.
- **Web UI not loading via Ingress**
  - Restart the add-on; ensure no other host service uses the same port.
- **Want to reset everything**
  - Stop the add-on, delete `/data/wg-easy` (via e.g. the *Studio Code Server* or
    *Samba* add-on), then restart — the first-run setup will run again.

---

## 🗺️ Supported architectures

`amd64`, `aarch64`. `armv7` is **not** supported (the upstream image has no armv7 build).

---

## 📄 License

The add-on glue code is MIT. The bundled wg-easy is licensed under **AGPL-3.0**
(see the [upstream project](https://github.com/wg-easy/wg-easy)).
