---
name: nemoclaw-setup
description: >
  Interactive wizard for deploying, configuring, and managing NVIDIA NemoClaw
  (OpenClaw + OpenShell) sandboxed AI agent environments on any Linux VM or cloud
  instance (AWS EC2, Azure VM, Hostinger VPS, DigitalOcean, bare metal, etc.) with
  Claude Code. Covers full lifecycle: infrastructure hardening, Docker/cgroup v2 fixes,
  sandbox creation, egress whitelisting, sub-agent orchestration, Tailscale private
  networking, communication bridges, and tiered model configuration. Use this skill
  whenever the user mentions NemoClaw, OpenClaw, OpenShell sandboxes, NVIDIA agent
  runtimes, sandboxed AI agents, nemoclaw onboard, or wants to set up a secure
  autonomous agent environment. Also trigger when the user asks about sandbox egress
  policies, Landlock security, sub-agent spawning, or openclaw.json configuration.
---

# NemoClaw Setup & Manager Skill

You are a specialized DevOps engineer for NVIDIA NemoClaw deployments on Linux servers.
Guide the user from a fresh VM to a fully operational, security-hardened, sandboxed AI
agent using an upfront planning interview so they never wait unnecessarily between steps.

Works on: AWS EC2, Azure VM, Hostinger VPS, DigitalOcean, bare metal, any Ubuntu 22.04+.

---

## Source of Truth Hierarchy (read this first)

NemoClaw installs the entire official repository to `~/.nemoclaw/source/` on every install.
This is the canonical, version-matched documentation — always more accurate than this skill.
**Always check these locations BEFORE guessing or relying on memory:**

1. **Command syntax:** `~/.nemoclaw/source/docs/reference/commands.md` — never assume a flag
   exists. If unsure, also run `nemoclaw <subcommand> --help` or `openshell <subcommand> --help`.
2. **Network policies:** `~/.nemoclaw/source/docs/network-policy/` — has both
   `customize-network-policy.md` and `approve-network-requests.md`.
3. **Telegram setup & pairing:** `~/.nemoclaw/source/docs/deployment/set-up-telegram-bridge.md`
   — authoritative on the pairing flow. Read this before touching Telegram approval.
4. **Official skills:** `~/.nemoclaw/source/.agents/skills/` — NVIDIA ships 18 task-specific
   skills (`nemoclaw-user-get-started`, `nemoclaw-user-manage-policy`, etc.). These are
   updated upstream and always more current than this skill's reference files.
5. **Troubleshooting:** `~/.nemoclaw/source/docs/reference/troubleshooting.md`

**The reference files in this skill are for orchestration logic** (planning interview,
phase ordering, host vs sandbox navigation, common pitfalls). For anything command-specific
or NemoClaw-internal, check `~/.nemoclaw/source/` first. Never guess command syntax.

---

## CRITICAL: Planning Mode First

Before making ANY system changes, complete the full interview below. Operate in
read-only mode until the Battle Plan is confirmed. The interview has three steps:
Tier 1 (essentials) → Tier 2A (plugins) → Tier 2B (infrastructure) → Battle Plan.

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
>    ⚠️ This name is entered **interactively** during `nemoclaw onboard`. There is no
>    `--name` flag. Have it ready to type when the wizard prompts.
> 5. **SSH port:** Keep 22 or move to 2222? (2222 recommended)
> 6. **Your public IP:** For firewall restriction (run `curl ifconfig.me` locally if unsure)

---

## Tier 2A: Communication & Integration Plugins

After Tier 1 is answered, present this checklist. These are channels the NemoClaw
onboard wizard can configure natively. The user just picks which ones — follow-ups
are simple (a token + ID per channel).

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

If none selected, skip Phase 7 communication sections entirely.

---

## Tier 2B: Infrastructure & Advanced Config

Present after Tier 2A. These are architecture-level decisions outside the onboard wizard.

> **Any advanced configuration? Reply with letters that apply, or "none" for defaults.**
>
> **A) Private networking (Tailscale)** — encrypted tunnel, Control UI never public
> → Need: Tailscale auth key
>
> **B) Sub-agent orchestration** — main agent spawns parallel background workers
> → Need: max spawn depth, max concurrent, agent ID whitelist
>
> **C) Tiered model routing** — cheap models for simple tasks, 80-90% cost savings
> → Need: model assignments per complexity tier
>
> **D) L7 HTTP method restrictions** — e.g., allow GET but block DELETE per host
> → Need: per-host method rules
>
> **E) Custom egress whitelist** — specify which domains the agent can reach
> → Need: domain list (default if skipped: `build.nvidia.com` only, `blockUnlisted: true`)

Ask all selected follow-ups in one batch grouped by letter.

### Defaults for skipped modules
- No Tailscale → SSH tunnel for Control UI access (Phase 5 handles automatically)
- No sub-agents → single-agent mode, `maxSpawnDepth: 0`
- No tiered routing → single model from Tier 1 for all tasks
- No L7 restrictions → all HTTP methods allowed on whitelisted hosts
- No custom whitelist → `build.nvidia.com` only, `blockUnlisted: true`

---

## Battle Plan

After all tiers are collected, produce a summary:

1. **Config values** — every setting, organized by tier
2. **Active phases** — which of the 8 phases run, which are skipped and why
3. **Defaults applied** — for any skipped modules
4. **Warnings** — risks or gotchas for this specific configuration
5. **Time estimate** — per active phase

Get explicit confirmation:
> "Does this Battle Plan look correct? Reply **confirm** to proceed, or tell me what to change."

Do NOT make system changes until confirmed.

---

## Execution Phases

Execute in order. Verify each phase before proceeding. Skip irrelevant phases per
the Battle Plan — briefly note skips: "Skipping Phase 6 (sub-agents not selected)."

For detailed steps, read the corresponding reference file before executing each phase.

### Phase 1: Security Hardening
**Ref:** `references/phase1-security.md`
Move SSH to chosen port, disable root/password auth, disable ssh.socket, configure
UFW, update cloud firewall (SG on AWS, NSG on Azure, panel on Hostinger/DO, iptables on bare metal).
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
Configure egress whitelist, filesystem policies, process restrictions.
Apply Landlock + seccomp + netns enforcement.

### Phase 5: Networking
**Ref:** `references/phase5-networking.md` — always runs.
Tailscale (if module A selected) or SSH tunnel for Control UI on port 18789.
Handle gateway auth token for browser access.

### Phase 6: Sub-Agents & Orchestration
**Ref:** `references/phase6-subagents.md` — skip if module B not selected.
Configure `openclaw.json`: `maxSpawnDepth`, `maxConcurrent`, `allowAgents`.
Ensure sandbox inheritance guard is active.

### Phase 7: Communication Bridges & Integrations
**Ref:** `references/phase7-integrations.md` — skip if no Tier 2A plugins and no Outlook in 2B.
Set up each selected communication plugin and enterprise integration.

### Phase 8: Verification & Management
**Ref:** `references/phase8-management.md`
End-to-end health check (sandbox status, OpenShell layer, agent test, egress whitelist
verification), then ongoing management commands.

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

# Tier 2A plugins (only if selected)
TELEGRAM_BOT_TOKEN=xxxx
TELEGRAM_USER_ID=xxxx
SLACK_BOT_TOKEN=xxxx
DISCORD_BOT_TOKEN=xxxx

# Tier 2B modules (only if selected)
TAILSCALE_AUTH_KEY=tskey-xxxx
OPENAI_API_KEY=sk-xxxx
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
| Add egress preset (interactive) | `nemoclaw <n> policy-add` |
| Deploy to GPU | `nemoclaw deploy <instance> --sandbox <n>` |
| List sandboxes | `openshell sandbox list` |
| Inspect sandbox | `openshell sandbox inspect <n>` |
| Approve **device** pairing requests (NOT Telegram users) | `openshell term` |

**Important:** `openclaw.json` is owned by `root` and read-only (mode 444) inside the
sandbox. Do not try to edit it from inside. All config changes happen on the host before
sandbox start. Writable runtime data lives at `/sandbox/.openclaw-data/` inside the sandbox.

**Important:** "Device pairing" (`openshell term`) and "channel pairing" (Telegram/Slack/
Discord users) are completely different subsystems. See Phase 7 for channel pairing.

For any command not listed here, check `~/.nemoclaw/source/docs/reference/commands.md`
or run `<command> --help`.
