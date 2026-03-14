# UniFi OS Server

<a href="https://github.com/jsoyer/unifi-os-server/pkgs/container/unifi-os-server"><img src="https://ghcr-badge.egpl.dev/jsoyer/unifi-os-server/latest_tag?trim=major&label=version&color=steelblue" alt="Latest version"></a>
<a href="https://github.com/jsoyer/unifi-os-server/actions/workflows/publish.yml"><img src="https://img.shields.io/github/actions/workflow/status/jsoyer/unifi-os-server/publish.yml?logo=githubactions&logoColor=white&label=Build" alt="Build status"></a>
<a href="https://github.com/jsoyer/unifi-os-server/pkgs/container/unifi-os-server"><img src="https://ghcr-badge.egpl.dev/jsoyer/unifi-os-server/size?label=image%20size" alt="Image size"></a>

Run [UniFi OS Server](https://blog.ui.com/article/introducing-unifi-os-server) on Docker or Kubernetes with multi-architecture support (amd64/arm64).

> **UniFi OS Server is the new standard for self-hosting UniFi**, replacing the legacy UniFi Network Server. It delivers the same management experience as UniFi-native hardware -- including Organizations, IdP Integration, Site Magic SD-WAN, and Site Manager for centralized multi-site control.
>
> <https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi>

## Quick Start

```bash
docker pull ghcr.io/jsoyer/unifi-os-server:latest
```

Or with Docker Compose:

```bash
git clone https://github.com/jsoyer/unifi-os-server.git
cd unifi-os-server
# Edit docker-compose.yaml: set UOS_SYSTEM_IP and volume paths
docker compose up -d
```

Access the web UI at **https://localhost:11443**

## Installation

### Docker Compose

See [docker-compose.yaml](docker-compose.yaml) for a complete example.

```yaml
services:
  unifi-os-server:
    image: ghcr.io/jsoyer/unifi-os-server:latest
    container_name: unifi-os-server
    privileged: true  # Required for systemd
    environment:
      - UOS_SYSTEM_IP=unifi.example.com
    volumes:
      - ./data/persistent:/persistent
      - ./data/var-log:/var/log
      - ./data/data:/data
      - ./data/srv:/srv
      - ./data/var-lib-unifi:/var/lib/unifi
      - ./data/var-lib-mongodb:/var/lib/mongodb
      - ./data/etc-rabbitmq-ssl:/etc/rabbitmq/ssl
    ports:
      - 11443:443      # Web UI
      - 8080:8080      # Device communication
      - 3478:3478/udp  # STUN
      - 10003:10003/udp # Device discovery
    restart: unless-stopped
```

### Kubernetes

Apply the manifests from the [kubernetes/](kubernetes/) directory:

```bash
kubectl create namespace unifi
kubectl apply -f kubernetes/
```

Included manifests:

| File | Description |
|------|-------------|
| [deployment.yaml](kubernetes/deployment.yaml) | Container spec with startup/liveness/readiness probes and resource limits |
| [service.yaml](kubernetes/service.yaml) | ClusterIP services for all TCP/UDP ports |
| [ingress.yaml](kubernetes/ingress.yaml) | nginx ingress with HTTPS backend and timeout tuning |
| [pvc.yaml](kubernetes/pvc.yaml) | 32 Gi PersistentVolumeClaim (Longhorn) |

The ingress controller must be configured for TCP/UDP passthrough. See [ingress-nginx](https://github.com/kubernetes/ingress-nginx) Helm values:

```yaml
tcp:
  8080: "unifi/unifi-os-server-communication-svc:8080"
udp:
  3478: "unifi/unifi-os-server-stun-svc:3478"
  10003: "unifi/unifi-os-server-discovery-svc:10003"
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `UOS_SYSTEM_IP` | Yes | -- | Hostname or IP for device inform and management |
| `HARDWARE_PLATFORM` | No | Auto-detected | Override platform detection (`synology`) |
| `UOS_UUID` | No | Generated | Persistent instance UUID |
| `FIRMWARE_PLATFORM` | No | Auto-detected | Override firmware platform (`linux-x64`, `linux-arm64`) |

### Device Adoption

1. SSH into the device (default: `ubnt`/`ubnt`)
2. Run: `set-inform http://<UOS_SYSTEM_IP>:8080/inform`
3. Adopt from the web UI

### Ports

**Required:**

| Protocol | Port | Service |
|----------|------|---------|
| TCP | 11443 | Web UI (maps to container 443) |
| TCP | 8080 | Device communication |
| UDP | 3478 | STUN (adoption + remote management) |
| UDP | 10003 | Device discovery |

**Optional:**

| Protocol | Port | Service |
|----------|------|---------|
| TCP | 8443 | Network Application |
| TCP | 5005 | RTP control |
| TCP | 9543 | Identity Hub |
| TCP | 6789 | Mobile speed test |
| TCP | 8444 | Hotspot portal (HTTPS) |
| TCP | 8880-8882 | Hotspot redirect (HTTP) |
| TCP | 11084 | Site Supervisor |
| TCP | 5671 | AQMPS |
| UDP | 5514 | Remote syslog |

## Building

The Dockerfile uses `TARGETARCH` (injected by buildx) to automatically select the correct base image per platform:

```dockerfile
ARG BASE_VERSION=0.0.54
ARG TARGETARCH
FROM ghcr.io/lemker/uosserver:${BASE_VERSION}-linux-${TARGETARCH}
```

### Local Build

```bash
# Native architecture (auto-detected)
docker build -t unifi-os-server .

# Multi-architecture
docker buildx build --platform linux/amd64,linux/arm64 -t unifi-os-server .
```

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `BASE_VERSION` | `0.0.54` | Base image version from `ghcr.io/lemker/uosserver` |

## CI/CD Pipeline

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Build & Test](../../actions/workflows/build.yml) | Pull requests | Build + Trivy scan + multi-arch validation |
| [Publish](../../actions/workflows/publish.yml) | Push to `main` | Build multi-arch, push to GHCR, Trivy, cosign sign, SBOM, GitHub release |
| [Check for New Releases](../../actions/workflows/release-check.yaml) | Daily cron | Poll Ubiquiti API, extract base images, create update PR |
| [Close Stale Issues](../../actions/workflows/stale.yml) | Daily cron | Auto-close inactive issues/PRs after 30 days |

### Supply Chain Security

Published images include:
- **Trivy vulnerability scanning** (CRITICAL/HIGH)
- **Cosign keyless signing** via Sigstore/Fulcio
- **SBOM** in SPDX-JSON format attached to the image
- **Provenance attestation** (SLSA)

Verify a signed image:

```bash
cosign verify ghcr.io/jsoyer/unifi-os-server:latest \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'github.com/jsoyer/unifi-os-server'
```

## Architecture

The container runs systemd as PID 1, which manages all UniFi services internally (MongoDB, PostgreSQL, RabbitMQ, nginx, UniFi Network Application).

```
Container boot sequence:
  uos-entrypoint.sh (init)
    -> UUID management
    -> Platform detection (uname -m)
    -> Version/platform file writes
    -> Network interface setup (macvlan)
    -> Directory initialization (nginx, mongodb, rabbitmq)
    -> Synology patches (if applicable)
    -> UOS_SYSTEM_IP injection
  exec /sbin/init (systemd)
    -> MongoDB, PostgreSQL, RabbitMQ, nginx, UniFi services
```

### Why Privileged Mode?

The container requires `privileged: true` because systemd needs access to the host cgroup filesystem. This is a hard requirement of the upstream `uosserver` image architecture.

### Graceful Shutdown

`STOPSIGNAL SIGRTMIN+3` signals systemd for orderly shutdown. The Kubernetes deployment sets `terminationGracePeriodSeconds: 120` to allow MongoDB and RabbitMQ to flush and close cleanly.

## FAQ

**What is the difference between `uosserver` and `unifi-os-server`?**

`uosserver` is the raw image extracted from Ubiquiti's installer. `unifi-os-server` is a wrapper that adds an entrypoint with directory initialization, environment variable support, health checks, Synology patches, and proper signal handling.

**Can I use this on Synology NAS?**

Yes. Set `HARDWARE_PLATFORM=synology` or let it auto-detect via DMI. The entrypoint applies systemd overrides for PostgreSQL, RabbitMQ, and ulp-go services.

**What are the minimum requirements?**

2+ CPU cores, 4 GB RAM (8 GB recommended), 50 GB storage. For Kubernetes: `requests: {cpu: 500m, memory: 2Gi}`, `limits: {memory: 4Gi}`.

**How do I update?**

```bash
docker compose pull && docker compose up -d
```

All data is persisted in mounted volumes.

## Troubleshooting

**Container won't start:** Check `docker compose logs unifi-os-server`. Common causes: missing `privileged: true`, port conflicts, insufficient memory.

**Device not adopting:** Verify the device can reach `UOS_SYSTEM_IP:8080`. Check `docker compose exec unifi-os-server cat /var/lib/unifi/system.properties` to confirm the IP is set correctly.

**High resource usage after startup:** MongoDB indexing on first boot can take 10-15 minutes. This is expected behavior.

## Credits

This project is a fork of [lemker/unifi-os-server](https://github.com/lemker/unifi-os-server) by [@lemker](https://github.com/lemker), who did the original work of extracting the UniFi OS Server from Ubiquiti's installer binary, building the base `uosserver` image, and creating the initial Docker/Kubernetes packaging. Thank you for making self-hosted UniFi OS Server possible.

## Links

- [Container Registry (GHCR)](https://github.com/jsoyer/unifi-os-server/pkgs/container/unifi-os-server)
- [Upstream: lemker/unifi-os-server](https://github.com/lemker/unifi-os-server)
- [UniFi Self-Hosting Documentation](https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi)
- [UniFi Community](https://community.ui.com)
