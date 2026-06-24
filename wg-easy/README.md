# wg-easy — Home Assistant Add-on

[![Upstream](https://img.shields.io/badge/wg--easy-v15-blue)](https://github.com/wg-easy/wg-easy)

Run a full **WireGuard VPN** with a polished **web UI** ([wg-easy](https://github.com/wg-easy/wg-easy)) inside Home Assistant, with persistent configuration and an unattended first-run setup.

> ⚠️ This is an unofficial community add-on that wraps the official `ghcr.io/wg-easy/wg-easy` image. It is not affiliated with the wg-easy project.

---

## ✨ Features

- 🌐 **WireGuard VPN** with a web admin UI
- 🧰 **Unattended setup** — the first run is auto-configured from the add-on options (admin user, endpoint, CIDR, DNS…)
- 💾 **Persistent data** — configuration & database survive add-on rebuilds/updates
- 🖥️ **Host networking** — VPN clients can reach the whole home network
- 🏗️ Multi-arch: **amd64** and **aarch64**

---

## ⚠️ Important: no Ingress (why, and how to access the UI)

wg-easy is a **single-page app (Nuxt)** that references all of its assets with
absolute root paths (e.g. `/_nuxt/...`). Home Assistant Ingress serves add-ons
under a sub-path (`/api/hassio_ingress/<token>/`), so those asset requests fall
**outside** Ingress and return **404**. This is a fundamental limitation, not a
bug — wg-easy simply isn't "Ingress-aware".

For this reason the add-on does **not** use Ingress. The web UI is exposed
**directly on a TCP port** (`webui_port`, default `51821`). Open it at:

```
http://<HA_IP>:51821
```

For remote/secure access, put it behind your own **HTTPS reverse proxy**
(recommended) — see below.

---

## 📦 Install

### Option A — Local add-on
1. Copy the `wg-easy/` folder into `/addons/` (via the **Samba**/**SFTP** add-on).
2. In HA: **Settings → Add-ons → Add-on Store → ⋮ → Reload**.
3. Open the **wg-easy** card and click **Install**.

### Option B — Add-on repository
1. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Add the URL of your Git repository, then **Reload**.
3. Install the **wg-easy** add-on.

---

## ⚙️ Configuration

| Option | Required | Default | Notes |
|---|---|---|---|
| `host` | ✅ recommended | `""` | Public IP/domain clients connect to. Set later from the UI if empty. |
| `port` | ✅ | `51820` | WireGuard **UDP** port. Forward this UDP port on your router to HA. |
| `webui_port` | optional | `51821` | **TCP** port for the web UI. Reach at `http://<HA_IP>:<webui_port>`. |
| `username` | ✅ | `admin` | Admin username (first run only). |
| `password` | ✅ | `""` | Admin password (first run only). Choose a strong one. |
| `address` | optional | `10.8.0.0/24` | IPv4 CIDR. |
| `ipv6_address` | optional | `fdcc:ad94:bacf:61a3::/64` | IPv6 CIDR (set together with IPv4). |
| `dns` | optional | `1.1.1.1, 1.0.0.1` | DNS for clients. |
| `allowed_ips` | optional | `0.0.0.0/0, ::/0` | Traffic routed through the VPN. |
| `disable_ipv6` | optional | `false` | Disable IPv6. |
| `insecure` | optional | `true` | Allow login cookie over HTTP. Set to `false` ONLY behind HTTPS reverse proxy. |

### ⚠️ These options are applied **only on the first run**

In wg-easy v15 all settings live in a **database**. The add-on options seed that
database on first start (wg-easy *"unattended setup"*). After that, change host,
password, DNS, etc. **from the wg-easy UI**. Editing the add-on options later
will not overwrite an already-configured instance.

---

## 🚀 Usage

1. **Configure** the add-on (at least `host`, `username`, `password`) and **Save**.
2. **Forward UDP `port`** (default `51820`) on your router to the HA IP.
3. **Start** the add-on.
4. Open the web UI at **`http://<HA_IP>:51821`** and log in.
5. Create a client, scan the QR code / download the config on your device, and connect. 🎉

---

## 🔒 Secure access with a reverse proxy (recommended)

The UI supports HTTPS cookies only when `insecure: false`. Serve it behind your
reverse proxy (nginx, Caddy, Traefik, …) with a TLS certificate.

Example **nginx** virtual host (point a subdomain like `wg.example.com` to your HA IP):

```nginx
server {
    listen 443 ssl http2;
    server_name wg.example.com;

    ssl_certificate     /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    # wg-easy web UI
    location / {
        proxy_pass http://<HA_IP>:51821;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # WebSocket + streaming support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
```

Then set `insecure: false` in the add-on options (the login cookie will be
`Secure`, served over HTTPS). WireGuard **UDP** traffic still uses `port`
(default `51820`) — keep that forwarded on the router; it is unrelated to the
reverse proxy.

---

## 🧠 How it works

- The image is built `FROM ghcr.io/wg-easy/wg-easy:15` and adds `jq` + a small
  entrypoint, plus the **iptables-nft** backend (HA OS kernel is nftables-only).
- On start the entrypoint **symlinks `/etc/wireguard` → `/data/wg-easy`** so the
  SQLite database (`wg-easy.db`) and `wg0.conf` are stored on the persistent
  HA volume.
- The add-on options are mapped to wg-easy's `INIT_*` environment variables
  (first-run setup).
- Runs with **host networking** + `NET_ADMIN`/`SYS_MODULE` so WireGuard can
  create its interface and NAT rules, letting VPN clients reach the LAN.

---

## 🔧 Troubleshooting

- **Web UI returns 404 / blank page via Ingress**
  - Expected: wg-easy is not Ingress-compatible. Use the direct port
    `http://<HA_IP>:51821` or a reverse proxy (see above).
- **Can log in via HTTP but session doesn't persist**
  - Set `insecure: true` for plain-HTTP access, or serve the UI over HTTPS and
    set `insecure: false`.
- **Clients can't connect / handshake fails**
  - Check the router forwards **UDP** `51820` to the HA IP.
  - Make sure `host` (public endpoint) is correct and reachable.
- **`Operation not permitted` / interface errors**
  - Reboot HA OS once after first install of a privileged add-on.
- **Want to reset everything**
  - Stop the add-on, delete `/data/wg-easy` (via e.g. *Studio Code Server* or
    *Samba*), then restart — the first-run setup will run again.

---

## 🗺️ Supported architectures

`amd64`, `aarch64`. `armv7` is **not** supported (the upstream image has no armv7 build).

---

## 📄 License

The add-on glue code is MIT. The bundled wg-easy is licensed under **AGPL-3.0**
(see the [upstream project](https://github.com/wg-easy/wg-easy)).
