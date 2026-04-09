# Phase 2: Docker & cgroup v2 Configuration

## Overview
NemoClaw requires Docker with cgroup v2 in host mode. Ubuntu 24.04 uses cgroup v2
by default, but Docker's default cgroupns mode must be explicitly set.

## Steps

### 2.1 Install Docker (if not already installed)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

### 2.2 Add user to docker group
```bash
sudo usermod -aG docker $USER
```

**Critical:** The current shell session does NOT pick up the new group. You must either:
- Run `newgrp docker` (applies to current shell only), OR
- Fully disconnect and reconnect SSH

Verify:
```bash
groups    # must include 'docker'
docker ps # must succeed without sudo
```

### 2.3 Configure cgroup v2 host mode
The `nemoclaw onboard` wizard checks for this. Set it preemptively:

```bash
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "default-cgroupns-mode": "host"
}
EOF
sudo systemctl restart docker
```

Verify:
```bash
docker info | grep -i cgroup
```
Expected output should include:
```
Cgroup Driver: systemd
Cgroup Version: 2
```

### 2.4 Verify Docker is accessible
```bash
docker run --rm hello-world
```

### 2.5 Run NemoClaw Docker setup (if available)
```bash
sudo nemoclaw setup-spark
```
This automates the Docker and cgroup v2 adjustments. Run it if the `nemoclaw` binary
is already installed. If not, this will be handled in Phase 3.

## Common Issues

**"Docker is not running" during onboard even though dockerd is active:**
This is almost always a group permission issue. The `groups` command won't show `docker`
until you've refreshed your session. Run `newgrp docker` or reconnect SSH.

**Container init errors:**
Usually caused by missing cgroup v2 host mode configuration. Apply the daemon.json fix above.
