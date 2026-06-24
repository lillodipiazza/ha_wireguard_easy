#!/bin/sh
# =============================================================================
#  wg-easy Home Assistant add-on entrypoint
#
#  1. Points /etc/wireguard at the persistent add-on data dir (/data).
#  2. Reads the add-on options (/data/options.json) and maps them to the
#     wg-easy v15 environment variables (first-run "unattended setup").
#  3. Starts the official wg-easy process tree (dumb-init -> node server).
# =============================================================================
set -eu

OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"

log() { printf '\033[1;34m[wg-easy]\033[0m %s\n' "$*"; }

log "Home Assistant add-on starting (upstream wg-easy v15)."

# -----------------------------------------------------------------------------
# 1. Persistent storage
#    wg-easy v15 keeps everything (SQLite DB + wg0.conf) under /etc/wireguard.
#    We relocate it onto the persistent HA volume so config survives rebuilds.
# -----------------------------------------------------------------------------
WG_DATA_DIR="/data/wg-easy"
log "Using persistent data dir: ${WG_DATA_DIR}"
mkdir -p "${WG_DATA_DIR}"

if [ -L /etc/wireguard ]; then
  log "/etc/wireguard already symlinked."
elif [ -d /etc/wireguard ]; then
  log "Migrating existing /etc/wireguard into ${WG_DATA_DIR}."
  cp -an /etc/wireguard/. "${WG_DATA_DIR}/" 2>/dev/null || true
  rm -rf /etc/wireguard
  ln -s "${WG_DATA_DIR}" /etc/wireguard
else
  ln -s "${WG_DATA_DIR}" /etc/wireguard
fi

# -----------------------------------------------------------------------------
# 2. Read add-on options (with safe defaults)
# -----------------------------------------------------------------------------
read_opt() {
  # $1 = jq expression (e.g. '.host'), $2 = default value (raw jq literal)
  local expr="$1"
  local def="$2"
  if [ -f "${OPTIONS_FILE}" ]; then
    jq -r "${expr} // ${def}" "${OPTIONS_FILE}"
  else
    # Fallback when run outside Home Assistant (debugging).
    echo "${def}" | sed -e 's/^"//' -e 's/"$//'
  fi
}

read_optb() {
  # Same as read_opt but coerces booleans to "true"/"false".
  local val
  val="$(read_opt "$1" "$2")"
  case "${val}" in
    true|True|TRUE|1) echo "true" ;;
    *) echo "false" ;;
  esac
}

OPT_HOST="$(read_opt  '.host'         '""')"
OPT_PORT="$(read_opt  '.port'         '51820')"
OPT_USERNAME="$(read_opt  '.username'     '"admin"')"
OPT_PASSWORD="$(read_opt  '.password'     '""')"
OPT_IPV4_CIDR="$(read_opt  '.address'      '"10.8.0.0/24"')"
OPT_IPV6_CIDR="$(read_opt  '.ipv6_address' '"fdcc:ad94:bacf:61a3::/64"')"
OPT_DNS="$(read_opt  '.dns'          '"1.1.1.1, 1.0.0.1"')"
OPT_ALLOWED_IPS="$(read_opt  '.allowed_ips'  '"0.0.0.0/0, ::/0"')"
OPT_DISABLE_IPV6="$(read_optb '.disable_ipv6' 'false')"
OPT_INSECURE="$(read_optb '.insecure'     'false')"

# -----------------------------------------------------------------------------
# 3. Web UI port -> Home Assistant Ingress
#
#    HA Supervisor proxies Ingress traffic to  <gateway>:<ingress_port>.
#    IMPORTANT: the Supervisor does NOT pass the Ingress port to the container
#    as an env var, so the add-on cannot use a dynamic (ingress_port: 0).
#    The listening port below MUST equal the fixed `ingress_port` declared in
#    config.yaml (51821). We still honor a supervisor-injected INGRESS_PORT if
#    a future Supervisor version provides one.
# -----------------------------------------------------------------------------
HA_INGRESS_PORT="51821"
export PORT="${INGRESS_PORT:-${HA_INGRESS_PORT}}"
log "Web UI listening on port ${PORT} (HA Ingress)."

export INSECURE="${OPT_INSECURE}"
export DISABLE_IPV6="${OPT_DISABLE_IPV6}"

# -----------------------------------------------------------------------------
# 4. First-run unattended setup (INIT_* variables)
#    wg-easy only consumes these while its setup step is not yet completed.
# -----------------------------------------------------------------------------
export INIT_ENABLED="true"
export INIT_USERNAME="${OPT_USERNAME}"
export INIT_PASSWORD="${OPT_PASSWORD}"
export INIT_HOST="${OPT_HOST}"
export INIT_PORT="${OPT_PORT}"
export INIT_DNS="${OPT_DNS}"
export INIT_IPV4_CIDR="${OPT_IPV4_CIDR}"
export INIT_IPV6_CIDR="${OPT_IPV6_CIDR}"
export INIT_ALLOWED_IPS="${OPT_ALLOWED_IPS}"

if [ -z "${OPT_HOST}" ]; then
  log "WARNING: option 'host' is empty. Set the public endpoint from the"
  log "         wg-easy UI (Configure -> Host) after the first start."
fi

log "---------------------------------------------------"
log " WireGuard UDP port : ${OPT_PORT}  (host network)"
log " Public endpoint    : ${OPT_HOST:-<not set>}"
log " Admin user         : ${OPT_USERNAME}"
log " IPv4 / IPv6 CIDR   : ${OPT_IPV4_CIDR} / ${OPT_IPV6_CIDR}"
log " DNS                : ${OPT_DNS}"
log " Allowed IPs        : ${OPT_ALLOWED_IPS}"
log "---------------------------------------------------"

# -----------------------------------------------------------------------------
# 5. Enable IP forwarding (required for VPN clients to reach LAN/internet).
#    HA OS usually already sets this, but some setups reset it. Best effort:
#    the writes may fail on read-only /proc, which is non-fatal.
# -----------------------------------------------------------------------------
for s in \
  "net.ipv4.ip_forward" \
  "net.ipv6.conf.all.forwarding" \
  "net.ipv6.conf.default.forwarding"; do
  if sysctl -w "${s}=1" >/dev/null 2>&1; then
    log "sysctl ${s}=1 OK"
  else
    log "sysctl ${s} not settable (already on or read-only) - ignoring."
  fi
done

# -----------------------------------------------------------------------------
# 6. Launch wg-easy (original upstream command)
# -----------------------------------------------------------------------------
cd /app
log "Starting wg-easy..."
exec /usr/bin/dumb-init node server/index.mjs
