# Troubleshooting Reference

Quick index of common errors encountered during NemoClaw setup and operation.

## ⚠️ First step for any unknown error

**Before debugging anything, check the canonical NVIDIA documentation that ships with
your NemoClaw install:**

```bash
ls ~/.nemoclaw/source/docs/                    # general docs
cat ~/.nemoclaw/source/docs/reference/troubleshooting.md  # official troubleshooting
cat ~/.nemoclaw/source/docs/reference/commands.md         # command reference
```

When you don't know if a command or flag exists, **always run `--help` first** rather
than guessing:
```bash
nemoclaw --help
nemoclaw <subcommand> --help
openshell --help
openshell <subcommand> --help
```

Most issues in this troubleshooting file were caused by guessing flags that don't
exist or assuming behavior that contradicted the canonical docs.

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

### AI agent in same shell still can't access docker after `usermod`
**Symptom:** You (the AI agent) added the user to docker group earlier in the same
session, but `docker info` still returns permission denied. `newgrp docker` doesn't
help because you can't replace your own shell as a non-interactive process.
**Fix:** Prefix Docker-dependent commands with `sg docker -c "..."`:
```bash
sg docker -c "docker info"
sg docker -c "nemoclaw onboard"
```
The user should reconnect SSH after the session ends to get group membership normally.

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

### `npm install -g nemoclaw` installed but command does nothing
**Symptom:** Installed via npm, `nemoclaw` command exists but produces no output or
errors immediately.
**Cause:** The npm package named `nemoclaw` is a dead stub — it has no `bin`, no
`main`, and no functionality. Name-squatter or legacy.
**Fix:** Uninstall it and use the official installer:
```bash
npm uninstall -g nemoclaw
curl -fsSL https://nvidia.com/nemoclaw.sh | bash
```

### Node.js 18 errors during install or runtime
**Symptom:** NemoClaw or OpenClaw runtime rejects the Node version, or produces
"unsupported syntax" / "ESM module" errors.
**Cause:** Ubuntu 22.04 ships Node 18 by default. NemoClaw requires Node 20+.
**Fix:** Install Node 22 via NodeSource:
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version   # should be 22.x
```

### `nemoclaw onboard --name <foo>` doesn't set the sandbox name
**Symptom:** Tried `--name` flag, sandbox got a different name (or default) anyway.
**Cause:** There is no `--name` flag. The sandbox name is collected interactively
during the wizard. Unknown flags are silently ignored.
**Fix:** Just run `nemoclaw onboard` and type the name when prompted.

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

### `nemoclaw policy update --allow-host` fails or "unknown flag"
**Symptom:** Tried to add an egress host with `policy update --allow-host`. Command
errors or does nothing.
**Cause:** That command/flag combination does not exist. The correct command is
`policy-add`, which is interactive.
**Fix:**
```bash
nemoclaw <n> policy-add
# Select preset or add custom host interactively
```
For full reference: `cat ~/.nemoclaw/source/docs/network-policy/customize-network-policy.md`

### Agent blocked on outbound request
**Symptom:** Agent can't reach an external API.
**Cause:** Domain not in `allowedEgressHosts` and `blockUnlisted: true`.
**Fix:**
```bash
openshell term            # approve a one-off request in TUI (device pairing only!)
nemoclaw <n> policy-add   # permanent — interactive preset selector
```

### Cannot edit `openclaw.json` from inside the sandbox
**Symptom:** Tried to `vim` or `echo >` to `/sandbox/.openclaw/openclaw.json`,
got "Permission denied" or "Read-only file system".
**Cause:** The file is owned by `root` with mode `444`. The sandbox user cannot
write to it. This is intentional — config is locked to prevent runtime tampering.
**Fix:** Change config on the host instead. Re-run `nemoclaw onboard` or use
`nemoclaw <n> policy-add`. Runtime data that the sandbox CAN write lives at
`/sandbox/.openclaw-data/` (credentials, logs, agent memory, etc.).

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

### `openshell ssh-proxy` fails with "unknown flag --gateway"
**Symptom:** Used `openshell ssh-proxy --gateway <name>`, got unknown flag error.
**Cause:** The correct flag is `--gateway-name`, not `--gateway`.
**Fix:**
```bash
openshell ssh-proxy --gateway-name nemoclaw --name <sandbox-name>
# Always run --help first to confirm flag names:
openshell ssh-proxy --help
```

### WebSocket 1008 Policy Violation when scripting Control UI
**Symptom:** Custom WebSocket client connects to `ws://127.0.0.1:18789` and immediately
gets closed with code `1008 Policy Violation`.
**Cause:** The gateway rejected the auth payload format. Common reasons: sending a
`device` object before the server's challenge-response handshake completes, wrong field
order in the signed payload, missing Origin header, or conflicting `dangerouslyDisableDeviceAuth`
with a device object.
**Fix:** Almost always, the real fix is **don't script against the WebSocket**.
- If you're trying to approve **Telegram/Slack/Discord users** — you're in the wrong
  subsystem entirely. Those are channel pairings. Go to Phase 7. The Control UI
  WebSocket is for **device pairing** only (browsers/CLIs connecting to the gateway).
- If you're trying to approve **device** pairing, use the browser Control UI at
  `http://127.0.0.1:18789` instead of custom scripts.

### `openshell ssh-proxy --gateway` fails with flag error
**Symptom:** Tried `openshell ssh-proxy --gateway nemoclaw` and got an unknown flag error.
**Cause:** The correct flag is `--gateway-name`, not `--gateway`.
**Fix:**
```bash
openshell ssh-proxy --gateway-name nemoclaw --name <sandbox-name>
# When in doubt:
openshell ssh-proxy --help
```

### WebSocket 1008 Policy Violation on Control UI
**Symptom:** Scripted WebSocket client to `ws://127.0.0.1:18789/` gets immediate
`1008 Policy Violation` close frame.
**Cause:** The gateway rejected the auth payload. Common reasons:
- Sending a `device` object before the challenge-response handshake completes
- Wrong field order in the signed payload
- Missing or malformed `Origin` header
- Using `dangerouslyDisableDeviceAuth` while ALSO passing a device object (conflict)
**Fix:** Do not script against the WebSocket unless you have a specific need. Use the
browser-based Control UI instead (Section 5.7). **If you reached this trying to approve
Telegram pairing, stop — you're in the wrong subsystem. See Phase 7 for channel pairing.**

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

## Communication Plugins (Phase 7)

### Telegram bot not responding
**Symptom:** Messages sent to bot, no response, or bot replies with a pairing code.
**Most common cause (check first):** The default `dmPolicy` is `pairing` — new users
must be approved before the bot responds to them. **This is by design, not a bug.**
**Fix:** See Phase 7 Telegram section — approve the pairing via one of three methods:
```bash
# Method A: CLI (if available in your version)
openclaw pairing approve --channel telegram --code <PAIRING_CODE>

# Method B: Read canonical docs
cat ~/.nemoclaw/source/docs/deployment/set-up-telegram-bridge.md

# Method C: Filesystem fallback (from inside the sandbox)
echo '{"version":1,"allowFrom":["<TELEGRAM_USER_ID>"]}' > /sandbox/.openclaw-data/credentials/telegram-main-allowFrom.json
echo '{"version":1,"requests":[]}' > /sandbox/.openclaw-data/credentials/telegram-pairing.json
```
Also check: is `api.telegram.org` in the egress whitelist? Bot token correct?
```bash
nemoclaw <n> logs --follow | grep telegram
```

### Trying to approve Telegram pairing via Control UI / WebSocket
**Symptom:** Got a Telegram pairing code, tried to approve it via the Control UI
WebSocket with `device.pair.approve` RPC, getting 1008 errors or no effect.
**Cause:** **Device pairing and channel pairing are completely separate subsystems.**
`device.pair.*` methods approve browsers and CLI clients pairing to the gateway.
They have nothing to do with Telegram user pairing.
**Fix:** Stop using the WebSocket entirely for this. Use one of the three methods
above. Write to `/sandbox/.openclaw-data/credentials/telegram-main-allowFrom.json`
as a last resort.

### Slack bot not responding
**Symptom:** Messages in channel, no agent response.
**Check:** Are all three Slack domains whitelisted (`slack.com`, `api.slack.com`, `wss-primary.slack.com`)?
**Common causes:** Missing bot scopes (`chat:write`, `channels:read`), wrong channel ID,
token is a user token instead of bot token (`xoxb-`).

### Discord bot offline
**Symptom:** Bot shows as offline in server.
**Check:** Are `discord.com` and `gateway.discord.gg` whitelisted?
**Common causes:** Bot not invited to server with correct permissions, missing Gateway Intents
(enable Message Content Intent in Discord developer portal).

### Webhook not receiving events
**Symptom:** No payloads arriving at webhook endpoint.
**Check:** Is the webhook domain in the egress whitelist?
**Common causes:** Wrong URL, auth header mismatch, endpoint not accepting POST,
HTTPS certificate issues.

### Microsoft Graph authentication failing
**Symptom:** "Unauthorized" or "InvalidAuthenticationToken" errors.
**Check:** Is `login.microsoftonline.com` whitelisted (needed for token exchange)?
**Common causes:** Client secret expired, wrong tenant ID, insufficient API permissions.

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
env | grep -E 'NVIDIA|NEMOCLAW|TAILSCALE|TELEGRAM|SLACK|DISCORD|MSGRAPH'
```
