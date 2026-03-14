ARG BASE_TAG=0.0.54-linux-amd64
FROM ghcr.io/lemker/uosserver:${BASE_TAG}

LABEL org.opencontainers.image.source="https://github.com/lemker/unifi-os-server" \
      org.opencontainers.image.description="UniFi OS Server for Docker and Kubernetes" \
      org.opencontainers.image.licenses="MIT"

ARG FIRMWARE_PLATFORM=linux-x64
ENV UOS_SERVER_VERSION="5.0.6" \
    FIRMWARE_PLATFORM="${FIRMWARE_PLATFORM}"

STOPSIGNAL SIGRTMIN+3

COPY --chmod=755 uos-entrypoint.sh /root/uos-entrypoint.sh

# systemd needs time to boot all services before health checks pass
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD curl -fs http://localhost/api/ping || exit 1

ENTRYPOINT ["/root/uos-entrypoint.sh"]
