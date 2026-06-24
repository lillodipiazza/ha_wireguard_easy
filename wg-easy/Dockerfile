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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Take over the entrypoint; the original command (dumb-init + node server) is
# launched at the end of entrypoint.sh.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
