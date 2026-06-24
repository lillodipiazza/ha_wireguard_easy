## Home Assistant add-on image for wg-easy
##
# Builds on top of the official multi-arch wg-easy image and adds everything
# needed for the Home Assistant integration (jq to read /data/options.json and
# a small entrypoint that wires the add-on options into wg-easy's environment).
#
# Override the upstream tag at build time, e.g.:
#   docker build --build-arg WG_EASY_VERSION=15.3 -t ghcr.io/wg-easy/wg-easy .
ARG WG_EASY_VERSION=15
FROM ghcr.io/wg-easy/wg-easy:${WG_EASY_VERSION}

# jq is used by the entrypoint to parse /data/options.json.
RUN apk add --no-cache jq

# Home Assistant OS ships a modern nftables-only kernel (Linux 6.x): it has
# NO legacy `ip_tables` module. The upstream wg-easy image forcefully selects
# `iptables-legacy`, which then crashes WireGuard startup with:
#   modprobe: FATAL: Module ip_tables not found in directory /lib/modules/...
#
# Alpine's `iptables` package already symlinks `iptables -> xtables-nft-multi`
# (nft backend) by default; wg-easy overrides that via update-alternatives to
# legacy. We restore the nft symlinks directly so iptables talks to the in-kernel
# `nf_tables` subsystem (always present on HA OS). This mirrors Alpine's
# intended default and matches the upstream "Podman + nftables" guidance.
RUN for b in iptables iptables-restore iptables-save \
             ip6tables ip6tables-restore ip6tables-save; do \
        ln -sf /usr/sbin/xtables-nft-multi "/usr/sbin/${b}"; \
    done

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Take over the entrypoint; the original command (dumb-init + node server) is
# launched at the end of entrypoint.sh.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
