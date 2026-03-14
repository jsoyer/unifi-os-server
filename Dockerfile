ARG BASE_VERSION=0.0.54
ARG TARGETARCH
FROM ghcr.io/lemker/uosserver:${BASE_VERSION}-linux-${TARGETARCH}

LABEL org.opencontainers.image.source="https://github.com/lemker/unifi-os-server" \
      org.opencontainers.image.description="UniFi OS Server for Docker and Kubernetes" \
      org.opencontainers.image.licenses="MIT"

ENV UOS_SERVER_VERSION="5.0.6"

# SIGRTMIN+3 is the correct shutdown signal for systemd containers
STOPSIGNAL SIGRTMIN+3

COPY --chmod=755 uos-entrypoint.sh /root/uos-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD curl -fs http://localhost/api/ping || exit 1

ENTRYPOINT ["/root/uos-entrypoint.sh"]
