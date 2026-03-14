# UniFi OS Server

<a href="https://github.com/lemker/unifi-os-server/pkgs/container/unifi-os-server"><img src="https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fgithub.com%2Flemker%2Funifi-os-server%2Fpkgs%2Fcontainer%2Funifi-os-server&search=(%3Fs)%3Cspan%5B%5E%3E%5D*%3E%5Cs*Total%5Cs%2Bdownloads%5Cs*%3C%2Fspan%3E.*%3F%3Ch3%5B%5E%3E%5D*%3E%5Cs*(%5B0-9%5D%5B0-9.%2C%5D*%5Cs*%5BKM%5D%3F)%5Cs*%3C%2Fh3%3E&replace=%241&logo=github&label=GHCR%20Pulls&cacheSeconds=3600"></a>
<a href="https://github.com/lemker/unifi-os-server/actions/workflows/release-check.yaml"><img src="https://img.shields.io/github/actions/workflow/status/lemker/unifi-os-server/release-check.yaml?logo=githubactions&logoColor=white&label=Actions"></a>

Run [UniFi OS Server](https://blog.ui.com/article/introducing-unifi-os-server) directly on Docker or Kubernetes.

> The **UniFi OS Server is the new standard for self-hosting UniFi**, replacing the legacy UniFi Network Server. While the Network Server provided basic hosting functionality, it lacked support for key UniFi OS features like Organizations, IdP Integration, or Site Magic SD-WAN. With a fully unified operating system, UniFi OS Server now delivers the same management experience as UniFi-native—including CloudKeys, Cloud Gateways, and Official UniFi Hosting—and is fully compatible with Site Manager for centralized, multi-site control.
>
> <https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi>

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building](#building)
- [Architecture](#architecture)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Troubleshooting](#troubleshooting)

## Overview

This project provides a containerized distribution of UniFi OS Server optimized for Docker and Kubernetes deployments. It addresses compatibility issues with the official `uosserver` image by providing proper directory structures, graceful signal handling, health probes, and environment variable configuration.

### What is UniFi OS Server?

UniFi OS Server is a unified operating system that combines all UniFi services into a single, cohesive platform. It supports:

- Multiple Organizations and Sites
- Identity Provider (IdP) Integration
- Site Magic SD-WAN
- Cloud Gateway integration
- Network application management
- Hotspot and portal services
- Remote device management

## Features

- **Multi-Architecture Support**: Automatically builds for different platforms (x86-64, ARM64)
- **Kubernetes Ready**: Includes health probes, resource limits, and proper signal handling
- **Hardware Aware**: Auto-detects and applies patches for Synology NAS systems
- **Persistent Configuration**: Maintains UUID and system settings across restarts
- **Health Checks**: Includes startup, liveness, and readiness probes
- **Graceful Shutdown**: Proper signal handling for clean container termination

## Quick Start

### Docker Compose

```bash
docker compose up -d
```

Access the UniFi OS Server at `https://localhost:11443`

See [docker-compose.yaml](https://github.com/lemker/unifi-os-server/blob/main/docker-compose.yaml) for the complete example.

### Kubernetes

```bash
kubectl apply -f kubernetes/
```

Update `unifi.example.com` in the Ingress manifest to your actual hostname.

See [kubernetes/](https://github.com/lemker/unifi-os-server/tree/main/kubernetes) for complete manifests.

## Installation

### Docker Compose

A complete example is provided in [docker-compose.yaml](https://github.com/lemker/unifi-os-server/blob/main/docker-compose.yaml).

Key configuration:
- **Image**: `ghcr.io/lemker/unifi-os-server:latest` (or specify a version tag)
- **Privileged Mode**: Required (container runs systemd services)
- **Volumes**: Multiple persistent volumes for data, logs, and certificates
- **Ports**: Core ports plus optional service-specific ports (see [Ports](#ports))
- **Environment**: Set `UOS_SYSTEM_IP` to your hostname or IP address

### Kubernetes

Complete manifests are provided in the [kubernetes/](https://github.com/lemker/unifi-os-server/tree/main/kubernetes) directory, including:

- **Deployment** (`kubernetes/deployment.yaml`): Container specification with health probes and resource limits
- **Services** (`kubernetes/services.yaml`): Service definitions for TCP/UDP port exposure
- **Ingress** (`kubernetes/ingress.yaml`): HTTP/HTTPS ingress for web UI
- **PersistentVolumeClaim** (`kubernetes/pvc.yaml`): Storage provisioning
- **Namespace** (`kubernetes/namespace.yaml`): Isolated namespace

#### Storage Requirements

The deployment uses a single PersistentVolumeClaim with subpaths for each component:
- `/persistent` - UniFi OS persistent data
- `/var/log` - Application logs
- `/data` - Core data directory
- `/srv` - Service data
- `/var/lib/unifi` - UniFi application data
- `/var/lib/mongodb` - MongoDB database
- `/etc/rabbitmq/ssl` - RabbitMQ SSL certificates

Recommended storage: **50-100 GB** depending on deployment size.

#### Ingress Configuration

The deployment uses [ingress-nginx](https://github.com/kubernetes/ingress-nginx) for ingress. Your ingress controller must be configured to accept extra TCP and UDP ports via service mapping.

Example `ingress-nginx` Helm values for TCP port passthrough:

```yaml
tcp:
  5005: "unifi/unifi-os-server-rtp-svc:5005" # RTP control (optional)
  9543: "unifi/unifi-os-server-id-hub-svc:9543" # Identity Hub (optional)
  6789: "unifi/unifi-os-server-mobile-speedtest-svc:6789" # Mobile speedtest (optional)
  8080: "unifi/unifi-os-server-communication-svc:8080" # Device communication (required)
  8443: "unifi/unifi-os-server-network-app-svc:8443" # Network app (optional)
  8444: "unifi/unifi-os-server-hotspot-secured-svc:8444" # Hotspot portal (optional)
  11084: "unifi/unifi-os-server-site-supervisor-svc:11084" # Site supervisor (optional)
  5671: "unifi/unifi-os-server-aqmps-svc:5671" # AQMPS (optional)
  8880: "unifi/unifi-os-server-hotspot-redirect-0-svc:8880" # Hotspot redirect (optional)
  8881: "unifi/unifi-os-server-hotspot-redirect-1-svc:8881" # Hotspot redirect (optional)
  8882: "unifi/unifi-os-server-hotspot-redirect-2-svc:8882" # Hotspot redirect (optional)
udp:
  3478: "unifi/unifi-os-server-stun-svc:3478" # STUN (required)
  5514: "unifi/unifi-os-server-syslog-svc:5514" # Syslog (optional)
  10003: "unifi/unifi-os-server-discovery-svc:10003" # Device discovery (required)
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `UOS_SYSTEM_IP` | Yes | None | Hostname or IP address for UniFi OS Server. Used for device inform and system identification. |
| `HARDWARE_PLATFORM` | No | Auto-detected | Manually override hardware platform detection. Accepted values: `linux-x64`, `synology`. |
| `UOS_UUID` | No | Generated | UUID for this UniFi OS Server instance. If not provided, a unique ID is generated on first run. |

#### UOS_SYSTEM_IP (Required)

This is the most critical configuration. Set it to the hostname or IP address where your UniFi OS Server is accessible from the network.

**For Device Adoption:**

1. SSH into the device (default credentials: `ubnt`/`ubnt`)
2. Run the inform command with your system IP:

   ```bash
   set-inform http://$UOS_SYSTEM_IP:8080/inform
   ```

3. The device will inform the server and appear in the adoption queue

**Example Values:**
- Hostname: `UOS_SYSTEM_IP=unifi.example.com`
- IP Address: `UOS_SYSTEM_IP=192.168.1.100`
- FQDN: `UOS_SYSTEM_IP=unifi-server.local.domain.com`

#### HARDWARE_PLATFORM

Normally auto-detected based on system DMI information or uname output. Override this if auto-detection fails or you're running on specialized hardware.

Currently supported platforms:
- `linux-x64` - Standard x86-64 Linux (default)
- `synology` - Synology NAS systems (applies specialized patches)

**Example for Synology:**

```bash
docker run -e HARDWARE_PLATFORM=synology ghcr.io/lemker/unifi-os-server:latest
```

#### UOS_UUID

A unique identifier for this UniFi OS Server installation. If not provided, one is automatically generated from `/proc/sys/kernel/random/uuid` on the first run and persisted to `/data/uos_uuid`.

**Example:**

```bash
docker run -e UOS_UUID=550e8400-e29b-41d4-a716-446655440000 \
  ghcr.io/lemker/unifi-os-server:latest
```

### Ports

| Protocol | Port | Direction | Service | Optional | Notes |
|----------|------|-----------|---------|----------|-------|
| TCP | 11443 | Ingress | UniFi OS Server GUI/API | No | Primary web interface |
| TCP | 8080 | Ingress | Device Communication | No | Device inform and management |
| UDP | 3478 | Both | STUN | No | Required for device adoption and remote management |
| UDP | 10003 | Ingress | Device Discovery | No | Device discovery during adoption |
| TCP | 5005 | Ingress | RTP Control | Yes | Real-time Transport Protocol control |
| TCP | 9543 | Ingress | Identity Hub | Yes | UniFi Identity Hub service |
| TCP | 6789 | Ingress | Mobile Speedtest | Yes | Mobile speed test service |
| TCP | 8443 | Ingress | Network App | Yes | UniFi Network Application |
| TCP | 8444 | Ingress | Hotspot Portal | Yes | Secure hotspot portal |
| UDP | 5514 | Ingress | Syslog | Yes | Remote syslog capture |
| TCP | 11084 | Ingress | Site Supervisor | Yes | UniFi Site Supervisor |
| TCP | 5671 | Ingress | AQMPS | Yes | Active Queue Management Policy Service |
| TCP | 8880-8882 | Ingress | Hotspot Redirect | Yes | Hotspot portal redirection |

**Minimum Required Ports (Docker):**
```bash
-p 11443:443     # Web UI
-p 8080:8080     # Device communication
-p 3478:3478/udp # STUN
-p 10003:10003/udp # Device discovery
```

## Building

### Overview

The project uses a unified `Dockerfile` with build-time arguments to support multiple platforms and configurations. This replaces the previous multi-Dockerfile approach.

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `BASE_TAG` | `0.0.54-linux-amd64` | Base image tag from `ghcr.io/lemker/uosserver` |
| `FIRMWARE_PLATFORM` | `linux-x64` | Target firmware platform for system identification |

### Build Examples

**Standard x86-64 Build:**

```bash
docker build -t unifi-os-server:latest .
```

**ARM64 Build:**

```bash
docker build \
  --build-arg BASE_TAG=0.0.54-linux-arm64 \
  --build-arg FIRMWARE_PLATFORM=linux-arm64 \
  -t unifi-os-server:arm64 .
```

**Synology-Optimized Build:**

```bash
docker build \
  --build-arg BASE_TAG=0.0.54-linux-amd64 \
  --build-arg FIRMWARE_PLATFORM=synology \
  -t unifi-os-server:synology .
```

### Multi-Architecture Builds

The CI/CD pipeline uses Docker buildx for multi-architecture builds:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/lemker/unifi-os-server:latest \
  --push .
```

This is handled automatically by the GitHub Actions workflow.

### Base Image

The Dockerfile builds on top of `ghcr.io/lemker/uosserver:<TAG>`, which provides the core UniFi OS Server components. The wrapper adds:

- Custom entrypoint with initialization logic
- Hardware platform detection and Synology patches
- Directory structure fixes
- Health check endpoints
- Environment variable configuration

## Architecture

### Container Structure

```
unifi-os-server (container)
├── /root/uos-entrypoint.sh      # Custom entrypoint script
├── /sbin/init                    # systemd init (from base)
├── /var/lib/unifi/               # UniFi application data
├── /var/lib/mongodb/             # MongoDB database
├── /var/log/                     # Application logs
├── /data/                        # Core data directory
├── /persistent/                  # UniFi OS persistent data
├── /srv/                         # Service data
└── /etc/rabbitmq/ssl/            # RabbitMQ SSL certs
```

### Entrypoint Initialization

The `uos-entrypoint.sh` script runs before systemd starts and handles:

1. **UUID Management**: Generates or persists the UniFi OS Server UUID
2. **Version Configuration**: Sets version string in `/usr/lib/version`
3. **Platform Configuration**: Writes platform info to `/usr/lib/platform`
4. **Network Setup**: Creates eth0 alias from tap0 if needed (macvlan)
5. **Directory Initialization**: Creates and sets permissions for log directories
6. **MongoDB Setup**: Initializes MongoDB log and lib directories
7. **RabbitMQ Setup**: Initializes RabbitMQ log directory
8. **Synology Patches**: Applies systemd overrides for Synology compatibility
9. **System IP Configuration**: Sets inform address in system.properties

All operations use `set -euo pipefail` for strict error handling.

### Systemd Signal Handling

The container uses `STOPSIGNAL SIGRTMIN+3` to properly signal systemd for graceful shutdown. This allows:

- Clean closure of device connections
- Proper database flushing
- Service shutdown in correct order
- 120-second termination grace period (Kubernetes)

### Health Probes (Kubernetes)

The deployment includes three health probes:

**Startup Probe** (30s initial delay, 10s period, 30 attempts):
- Waits up to 5 minutes for initial startup
- Uses `/api/ping` endpoint on port 80
- Allows service initialization time

**Readiness Probe** (15s period, 3 failures):
- Checks if service is accepting connections
- Uses `/api/ping` endpoint on port 80
- Fails after 3 consecutive failures

**Liveness Probe** (60s period, 3 failures):
- Monitors ongoing health
- Uses `/api/ping` endpoint on port 80
- Restarts container if unresponsive

## Frequently Asked Questions

### What is the difference between this image and the official `uosserver` image?

The official `ghcr.io/lemker/uosserver` image is provided by UniFi and extracted from the installation binary. This `unifi-os-server` image is a wrapper that:

1. **Adds Custom Entrypoint**: Initializes directories, manages UUIDs, and applies platform-specific patches
2. **Fixes Directory Structure**: Ensures proper permissions and ownership
3. **Enables Configuration**: Supports environment variables for `UOS_SYSTEM_IP` and `HARDWARE_PLATFORM`
4. **Hardware Support**: Auto-detects and applies patches for Synology systems
5. **Kubernetes Ready**: Includes health probes and proper signal handling
6. **CI/CD Optimized**: Single unified Dockerfile with build arguments instead of multiple versions

### Why does the container need privileged access?

UniFi OS Server runs every component as systemd services. This architecture requires:

- Access to the host's cgroup filesystem
- Ability to manage systemd services within the container
- Network namespace management
- Device access for various services

Privileged mode is necessary for systemd to function properly within the container.

### How do I adopt UniFi devices with this setup?

1. Ensure devices can reach `UOS_SYSTEM_IP:8080` from their network
2. SSH into the device (default: `ubnt`/`ubnt`)
3. Run: `set-inform http://$UOS_SYSTEM_IP:8080/inform`
4. The device should appear in the adoption queue within 30 seconds
5. Adopt the device from the UniFi OS Server web UI

### Can I use this on Synology NAS?

Yes. The container includes automatic Synology detection and patching. However:

- Synology DSM may have its own Docker integration
- Use `HARDWARE_PLATFORM=synology` for explicit support
- Resource constraints on NAS may limit functionality
- Consider network performance impact

### What are the minimum hardware requirements?

**Docker Compose:**
- CPU: 2+ cores
- RAM: 4 GB minimum, 8 GB recommended
- Storage: 50 GB for data and databases
- Network: 1 Gbps (gigabit) recommended

**Kubernetes:**
- CPU: 500m minimum, 1000m+ recommended
- Memory: 2 Gi minimum, 4 Gi recommended
- Storage: 50-100 GB persistent volume
- Network: Stable connectivity required

### How do I update UniFi OS Server?

1. Check available versions: `ghcr.io/lemker/unifi-os-server:tags`
2. Update Docker Compose: Change `image` tag and run `docker compose pull && docker compose up -d`
3. Update Kubernetes: Change `image` in deployment and apply: `kubectl apply -f kubernetes/deployment.yaml`

The container maintains all persistent data across version updates.

### How do I backup my configuration?

All persistent data is stored in mounted volumes. To backup:

**Docker Compose:**
```bash
docker compose exec unifi-os-server tar czf /backup/unifi-backup.tar.gz \
  /persistent /var/lib/unifi /var/lib/mongodb
docker compose cp unifi-os-server:/backup/unifi-backup.tar.gz ./unifi-backup.tar.gz
```

**Kubernetes:**
```bash
kubectl -n unifi cp unifi-os-server-pod:/persistent ./persistent-backup
kubectl -n unifi cp unifi-os-server-pod:/var/lib/unifi ./unifi-backup
kubectl -n unifi cp unifi-os-server-pod:/var/lib/mongodb ./mongodb-backup
```

### What is the difference between optional ports?

Some ports support optional UniFi OS features. Only expose ports for features you need:

- **Required**: 11443, 8080, 3478, 10003 - Core functionality
- **Recommended**: 8443 - Network application
- **Optional**: Others for specific use cases (hotspot, syslog, etc.)

Exposing unnecessary ports is a minor security risk.

### How do I check if the container is healthy?

**Docker Compose:**
```bash
docker compose ps
```

The `STATUS` column shows health: `healthy`, `unhealthy`, or `starting`.

**Kubernetes:**
```bash
kubectl -n unifi get pods
```

Check the `READY` column (2/2 means both startup and container ready).

View detailed health info:
```bash
kubectl -n unifi describe pod unifi-os-server-<hash>
```

### Why is my device not adopting?

Check these in order:

1. **Network Connectivity**: Device must reach `UOS_SYSTEM_IP:8080`
2. **Correct IP/Hostname**: Verify `UOS_SYSTEM_IP` is correct and resolvable
3. **Port Exposure**: Ensure 8080/TCP and 3478/UDP are accessible
4. **Device Credentials**: Use default `ubnt`/`ubnt` or configured credentials
5. **Firmware Version**: Device firmware may be incompatible
6. **Container Health**: Check `docker compose logs unifi-os-server`

### How do I manage multiple sites?

UniFi OS Server supports multiple sites and organizations directly in the web UI:

1. Create a Site in the UI
2. Assign devices to the site
3. Configure network settings per site
4. Use Site Manager for multi-site control

Multiple physical UniFi OS Server instances can be managed through Site Manager.

### Can I run this in high availability (HA)?

The current setup supports single-instance deployment only. For HA:

1. Set up multiple UniFi OS Server instances
2. Use Site Manager for centralized control
3. Configure DNS failover between instances
4. Each instance maintains independent data

Full database replication is not currently supported.

## Troubleshooting

### Container won't start

**Check logs:**
```bash
docker compose logs unifi-os-server
```

Common issues:
- Privileged mode not enabled: Add `privileged: true`
- Volume mount permissions: Ensure host directories are writable
- Port conflicts: Check if ports are already in use
- Insufficient resources: Verify CPU and memory availability

### Device adoption fails

**Debug steps:**

1. Verify connectivity from device to host:
   ```bash
   # From device
   ping $UOS_SYSTEM_IP
   telnet $UOS_SYSTEM_IP 8080
   ```

2. Check container logs:
   ```bash
   docker compose logs unifi-os-server | grep -i inform
   ```

3. Verify environment variable:
   ```bash
   docker compose exec unifi-os-server cat /var/lib/unifi/system.properties
   ```

4. Check network configuration:
   ```bash
   docker compose exec unifi-os-server ip addr show
   ```

### High CPU/Memory usage

**Check what's running:**
```bash
docker compose exec unifi-os-server systemctl status
```

**Common causes:**
- Database indexing (expected on startup, usually resolves in 10-15 minutes)
- Large number of devices
- High traffic volume
- Logs not rotating (check `/var/log` size)

### MongoDB won't start

**Check MongoDB logs:**
```bash
docker compose logs unifi-os-server | grep -i mongodb
```

**Common causes:**
- Corrupted database: Delete `/data/var/lib/mongodb` (if you have backups)
- Permission issues: Ensure mongodb user can access `/var/lib/mongodb`
- Disk full: Check available space

### Synology-specific issues

If running on Synology, ensure:
1. `HARDWARE_PLATFORM=synology` is set
2. SSH access is enabled on NAS
3. Required kernel modules are loaded (NET_ADMIN)
4. Sufficient disk space (Synology storage is often limited)

### Performance issues

**Optimization steps:**

1. **Increase Resource Limits** (Kubernetes):
   ```yaml
   resources:
     limits:
       memory: "8Gi"
       cpu: "2000m"
   ```

2. **Check Storage Performance**: Use fast SSDs for MongoDB
3. **Network Optimization**: Ensure low-latency, stable network
4. **Log Rotation**: Monitor `/var/log` size
5. **Device Count**: Large deployments may need dedicated hardware

### Getting Help

If issues persist:

1. **Check Logs**: `docker compose logs unifi-os-server` or `kubectl logs -n unifi unifi-os-server-<pod>`
2. **Review Configuration**: Verify all environment variables are correct
3. **GitHub Issues**: Check [existing issues](https://github.com/lemker/unifi-os-server/issues)
4. **UniFi Community**: Visit [UniFi Help Center](https://help.ui.com)

---

**Project Repository**: [github.com/lemker/unifi-os-server](https://github.com/lemker/unifi-os-server)

**Container Registry**: [ghcr.io/lemker/unifi-os-server](https://github.com/lemker/unifi-os-server/pkgs/container/unifi-os-server)

**UniFi Help**: [help.ui.com](https://help.ui.com)
