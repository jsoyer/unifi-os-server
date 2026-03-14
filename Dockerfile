ARG BASE_TAG=0.0.54-linux-amd64
FROM ghcr.io/lemker/uosserver:${BASE_TAG}

LABEL org.opencontainers.image.source="https://github.com/lemker/unifi-os-server"

ARG FIRMWARE_PLATFORM=linux-x64
ENV UOS_SERVER_VERSION="5.0.6" \
    FIRMWARE_PLATFORM="${FIRMWARE_PLATFORM}"

STOPSIGNAL SIGRTMIN+3

COPY --chmod=755 uos-entrypoint.sh /root/uos-entrypoint.sh
ENTRYPOINT ["/root/uos-entrypoint.sh"]
