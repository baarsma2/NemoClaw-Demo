# Phase 5: Networking (Tailscale / SSH Tunnels / Gateway)

## Overview
Configure private networking to avoid exposing the Control UI or WebSocket gateway
to the public internet. Two approaches: Tailscale (recommended) or SSH tunneling.

## Option A: Tailscale Private Networking (Recommended)

### 5.1 Install Tailscale
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 5.2 Authenticate
```bash
sudo tailscale up
```
This outputs an auth URL. Open it in your browser to link the server to your tailnet.

If using an auth key from the Battle Plan:
```bash
sudo tailscale up --authkey=<TAILSCALE_AUTH_KEY>
```

### 5.3 Get the Private IP
```bash
tailscale ip -4    # returns 100.x.x.x
```

### 5.4 Bind Gateway to Private Network Only
Configure the OpenClaw gateway to listen only on the Tailscale IP or loopback:
- In the gateway config, set the bind address to `100.x.x.x` or `127.0.0.1`
- This prevents any public ingress to the admin interface

### 5.5 Access from Your Machine
On your local machine (also on the tailnet):
```bash
# Access the Control UI directly via Tailscale IP
http://100.x.x.x:18789
```

## Option B: SSH Tunneling (Fallback)

If Tailscale is not used, access the Control UI via SSH tunnel.

### 5.6 Create the Tunnel
From your local machine:
```bash
ssh -i <key.pem> -p 2222 -L 18789:127.0.0.1:18789 ubuntu@<public-ip>
```

Then open in browser: `http://127.0.0.1:18789`

### 5.7 Handle Gateway Auth Token
The browser may show a "device identity required" error over tunneled connections.

Fix:
```bash
# On the server, inside the sandbox:
cat /sandbox/.openclaw/openclaw.json | grep -A5 "auth"
```

Copy the token value and access via:
```
http://127.0.0.1:18789/#token=REAL_TOKEN
```

**Use an incognito/private browser window** to avoid stale localStorage issues.

## VSCode SSH Tunnel Note
If you're already connected via VSCode Remote SSH on port 2222, you can set up
port forwarding directly in VSCode:
1. Open the "Ports" panel (Ctrl+Shift+P → "Forward a Port")
2. Forward port 18789
3. Access at `http://127.0.0.1:18789` in your local browser
