# Troubleshooting Reference

Quick index of common errors encountered during NemoClaw setup and operation.

---

## SSH & Security (Phase 1)

### Locked out after enabling UFW
**Symptom:** Cannot SSH to instance after `ufw enable`.
**Cause:** Forgot to `ufw allow 2222/tcp` before enabling, or SSH still on port 22.
**Fix:** Use your provider's web/serial console (AWS Instance Connect, Azure Serial Console,
Hostinger VNC, etc.). Or detach root volume, mount on another instance, edit
`/etc/ssh/sshd_config` and UFW rules, reattach.

### SSH still listening on port 22 after config change
**Symptom:** `ss -tlnp | grep :22` still shows sshd.
**Cause:** systemd `ssh.socket` is overriding sshd_config.
**Fix:**
```bash
sudo systemctl disable --now ssh.socket
sudo systemctl restart ssh
```

---

## Docker & cgroup (Phase 2)

### "Docker is not running" during nemoclaw onboard
**Symptom:** Onboarding wizard says Docker isn't running, but `systemctl status docker` shows active.
**Cause:** Current user not in `docker` group, or group membership not refreshed.
**Fix:**
```bash
sudo usermod -aG docker $USER
newgrp docker     # refresh in current shell
# OR reconnect SSH entirely
docker ps         # verify
```

### Container initialization errors
**Symptom:** Sandbox containers fail to start with cgroup-related errors.
**Cause:** Docker not configured with `default-cgroupns-mode: host`.
**Fix:** See Phase 2, step 2.3 — create/update `/etc/docker/daemon.json`.

---

## NemoClaw Installation (Phase 3)

### `nemoclaw: command not found`
**Symptom:** Binary not in PATH after installation.
**Cause:** Installer puts binary in `~/.local/bin/` which may not be in PATH.
**Fix:**
```bash
export PATH=$PATH:$HOME/.local/bin
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
```

### HTTP 403/404 during model validation
**Symptom:** Onboard wizard rejects model ID.
**Cause:** Truncated model ID — must include full prefix.
**Fix:** Use `nvidia/nemotron-3-super-120b-a12b` not just `nemotron-3-super-120b-a12b`.

### "NVIDIA API key missing or invalid"
**Symptom:** Inference provider authentication failed.
**Fix:**
```bash
export NVIDIA_API_KEY="nvapi-xxxxxxxxxxxx"
nemoclaw onboard   # re-run
```

---

## Sandbox & Policy (Phase 4)

### "Sandbox not found"
**Symptom:** `nemoclaw <n> status` says sandbox not found.
**Cause:** NemoClaw errors and OpenShell errors are separate systems.
**Fix:** Check both layers:
```bash
openshell sandbox list           # OpenShell layer
nemoclaw <n> status              # NemoClaw layer
```

### Agent blocked on outbound request
**Symptom:** Agent can't reach an external API.
**Cause:** Domain not in `allowedEgressHosts` and `blockUnlisted: true`.
**Fix:**
```bash
openshell term                                        # approve in TUI (temporary)
nemoclaw <n> policy update --allow-host <domain>      # permanent
```

### OpenShell not installed
**Symptom:** `openshell: command not found`.
**Fix:** Install NVIDIA OpenShell first, then re-run NemoClaw installer.

---

## Networking (Phase 5)

### "Device identity required" when accessing Control UI
**Symptom:** Browser shows identity error when accessing `127.0.0.1:18789` via tunnel.
**Cause:** Gateway auth state not persisting over tunneled HTTP.
**Fix:**
```bash
cat /sandbox/.openclaw/openclaw.json | grep -A5 "auth"
# Copy the token, then access:
# http://127.0.0.1:18789/#token=REAL_TOKEN
# Use incognito/private browser window
```

---

## Sub-Agents (Phase 6)

### "allowed: none" on sub-agents
**Symptom:** Sub-agents fail to spawn or show no permissions.
**Cause:** `allowAgents` placed in `agents.defaults` instead of the specific agent in `agents.list`.
**Fix:** Move `allowAgents` to the specific agent entry. See Phase 6, step 6.2.

### Sub-agents timing out
**Symptom:** Background workers killed before completing.
**Fix:** Increase `runTimeoutSeconds` in `openclaw.json` (default: 900).

---

## General Diagnostics

### Full debug log
```bash
nemoclaw <n> logs --follow --level debug
```

### Check all running processes
```bash
openshell sandbox list
docker ps
```

### Verify environment variables are set
```bash
env | grep -E 'NVIDIA|NEMOCLAW|TAILSCALE|TELEGRAM'
```
