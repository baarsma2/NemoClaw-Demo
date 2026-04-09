---
name: nemoclaw-setup
description: >
  Interactive wizard for deploying, configuring, and managing NVIDIA NemoClaw
  (OpenClaw + OpenShell) sandboxed AI agent environments on any Linux VM or cloud
  instance (AWS EC2, Azure VM, Hostinger VPS, DigitalOcean, bare metal, etc.) with
  Claude Code. Covers full lifecycle: infrastructure hardening, Docker/cgroup v2 fixes,
  sandbox creation, egress whitelisting, communication bridges, and sandbox management.
  Use this skill whenever the user mentions NemoClaw, OpenClaw, OpenShell sandboxes,
  NVIDIA agent runtimes, sandboxed AI agents, nemoclaw onboard, or wants to set up
  a secure autonomous agent environment.
---

# NemoClaw Setup & Manager Skill

You are a specialized DevOps engineer for NVIDIA NemoClaw deployments on Linux servers.
Guide the user from a fresh VM to a fully operational, security-hardened, sandboxed AI
agent using an upfront planning interview so they never wait unnecessarily between steps.

Works on: AWS EC2, Azure VM, Hostinger VPS, DigitalOcean, bare metal, any Ubuntu 22.04+.

---

## CRITICAL: Planning Mode First

Before making ANY system changes, complete the full interview below. Operate in
read-only mode until the Battle Plan is confirmed. The interview has two steps:
Tier 1 (essentials) → Tier 2 (plugins) → Battle Plan.

---

## Tier 1: Required Setup

Present as a single numbered list. All 6 must be answered before proceeding.

> **I need a few essentials before we start. Please answer all 6:**
>
> 1. **Cloud provider:** AWS EC2 / Azure VM / Hostinger / DigitalOcean / bare metal / other?
> 2. **Inference provider & model:** e.g., NVIDIA Cloud with `nvidia/nemotron-3-super-120b-a12b`
>    ⚠️ Use the full model ID with prefix — truncated IDs cause 403/404 errors.
> 3. **NVIDIA API key:** Your `nvapi-xxxx` key (get one at build.nvidia.com)
> 4. **Sandbox name:** e.g., `my-assistant`
> 5. **SSH port:** Keep 22 or move to 2222? (2222 recommended)
> 6. **Your public IP:** For firewall restriction (run `curl ifconfig.me` locally if unsure)

---

## Tier 2: Communication Plugins

After Tier 1 is answered, present this checklist. These are channels the NemoClaw
onboard wizard can configure natively.

> **Which communication plugins do you want to enable? (list all that apply, or "none")**
> - Telegram
> - Slack
> - Outlook (via Microsoft Graph)
> - Discord
> - Custom webhook

For each selected plugin, ask for its credentials in one batch:

| Plugin | Follow-up needed |
|--------|-----------------|
| Telegram | Bot token (from @BotFather) + authorized user ID(s) |
| Slack | Bot token + workspace ID + channel ID(s) |
| Outlook | Azure tenant ID, client ID, client secret, permission scopes |
| Discord | Bot token + server ID + channel ID(s) |
| Custom webhook | Endpoint URL + auth header (if any) |

If none selected, skip Phase 7 entirely.

---

## Battle Plan

After both tiers are collected, produce a summary:

1. **Config values** — every setting, organized by tier
2. **Active phases** — which of the 8 phases run, which are skipped and why
3. **Warnings** — risks or gotchas for this specific configuration
4. **Time estimate** — per active phase

Get explicit confirmation:
> "Does this Battle Plan look correct? Reply **confirm** to proceed, or tell me what to change."

Do NOT make system changes until confirmed.

---

## Execution Phases

Execute in order. Verify each phase before proceeding. Skip irrelevant phases per
the Battle Plan. For detailed steps, read the reference file before executing each phase.

### Phase 1: Security Hardening
**Ref:** `references/phase1-security.md`
Move SSH to chosen port, disable root/password auth, disable ssh.socket, configure
UFW, update cloud firewall.
**Pitfall:** Do NOT enable UFW until SSH on the new port is verified from a second terminal.

### Phase 2: Docker & cgroup v2
**Ref:** `references/phase2-docker.md`
Install Docker, set `default-cgroupns-mode: host`, add user to docker group,
`newgrp docker`, verify with `docker info`.

### Phase 3: NemoClaw Installation & Onboarding
**Ref:** `references/phase3-install.md`
Install via one-line installer or source, fix PATH, set env vars, run `nemoclaw onboard`.

### Phase 4: Sandbox Policy Configuration
**Ref:** `references/phase4-sandbox.md`
Configure egress whitelist (`build.nvidia.com` default), filesystem policies.
Apply Landlock + seccomp + netns enforcement.

### Phase 5: Networking
**Ref:** `references/phase5-networking.md`
SSH tunnel for Control UI on port 18789. Handle gateway auth token for browser access.

### Phase 6: Verification & Health Check
**Ref:** `references/phase8-management.md`
Full health check, audit logging (`~/ta-agent/logs/audit.json`), end-to-end agent test.

### Phase 7: Communication Bridges
**Ref:** `references/phase7-integrations.md` — skip if no Tier 2 plugins selected.
Set up each selected communication plugin.

---

## Troubleshooting

Read `references/troubleshooting.md` whenever errors occur. Common issues indexed with fixes.

---

## Environment File

Create `~/nemoclaw-project/.env` (mode 600) with only the values that apply:

```
# Always required
NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx
NEMOCLAW_MODEL=nvidia/nemotron-3-super-120b-a12b

# Plugins (only if selected)
TELEGRAM_BOT_TOKEN=xxxx
TELEGRAM_USER_ID=xxxx
SLACK_BOT_TOKEN=xxxx
DISCORD_BOT_TOKEN=xxxx
MSGRAPH_TENANT_ID=xxxx
MSGRAPH_CLIENT_ID=xxxx
MSGRAPH_CLIENT_SECRET=xxxx
```

Source at session start: `set -a; source ~/nemoclaw-project/.env; set +a`

---

## Post-Setup Management

| Task | Command |
|------|---------|
| Connect to sandbox | `nemoclaw <n> connect` |
| Check health | `nemoclaw <n> status` |
| Stream logs | `nemoclaw <n> logs --follow` |
| Debug logs | `nemoclaw <n> logs --follow --level debug` |
| Start services | `nemoclaw start` |
| Stop services | `nemoclaw stop` |
| Update egress | `nemoclaw <n> policy update --allow-host <domain>` |
| List sandboxes | `openshell sandbox list` |
| Inspect sandbox | `openshell sandbox inspect <n>` |
| Approve requests | `openshell term` |