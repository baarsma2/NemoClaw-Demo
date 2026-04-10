# Phase 4: Sandbox Policy Configuration

## Overview
Configure the sandbox's security policies: network egress, filesystem access, process
restrictions. NemoClaw operates on a "deny-by-default" egress policy — nothing gets
out unless explicitly whitelisted.

## Policy Layers

| Layer | Property | Effect | Hot-reloadable? |
|-------|----------|--------|-----------------|
| Network | `allowedEgressHosts` | Permits targeted domain access | Yes |
| Network | `blockUnlisted` | Blocks everything not in whitelist | Yes |
| Filesystem | `allowedPaths` | Restricts R/W to specific folders | No (locked at creation) |
| Process | seccomp + Landlock | Blocks privilege escalation, dangerous syscalls | No (locked at creation) |
| Inference | Reroutes model calls | Controls which backends are used | Yes |
| Binary | `binaries` | Limits which executables can use a route | Yes |

## Steps

### 4.1 Configure Network Egress Policy

The sandbox config file lives at the path shown during onboarding. Edit it to add
your whitelisted domains:

```yaml
network:
  blockUnlisted: true
  allowedEgressHosts:
    - build.nvidia.com
    # Add domains from Battle Plan here
```

If Tier 2A plugins were selected, include their required domains now:

| Plugin | Required egress domains |
|--------|----------------------|
| Telegram | `api.telegram.org` |
| Slack | `slack.com`, `api.slack.com`, `wss-primary.slack.com` |
| Discord | `discord.com`, `gateway.discord.gg` |
| Outlook/Graph | `graph.microsoft.com`, `login.microsoftonline.com` |
| Custom webhook | your webhook's domain |

Only add the rows that apply. Example with Telegram + Slack selected:
```yaml
network:
  blockUnlisted: true
  allowedEgressHosts:
    - build.nvidia.com
    - api.telegram.org
    - slack.com
    - api.slack.com
    - wss-primary.slack.com
```

### 4.2 L7 HTTP Method Restrictions (Module F — Optional)

Skip this section if Module F was not selected in Tier 2B.

L7 restrictions let you control which HTTP methods the agent can use per host.
This is most useful for APIs where the agent should read but never delete data.

**When to use this:**
- Enterprise APIs with destructive endpoints (Graph API, cloud provider APIs)
- Third-party APIs where accidental writes could cause damage
- Any host where you want read-only agent access

**When to skip:**
- Communication plugins (Telegram, Slack, Discord) — they need POST to send messages
- `build.nvidia.com` — inference calls require POST

```yaml
network:
  allowedEgressHosts:
    - host: docs.example.com
      protocol: rest
      methods: [GET]           # read-only access
    - host: graph.microsoft.com
      protocol: rest
      methods: [GET, POST]     # no DELETE — prevents accidental data loss
    - host: api.example.com
      protocol: rest
      methods: [GET, POST]     # no DELETE/PUT
```

### 4.3 Configure Filesystem Access

```yaml
filesystem:
  allowedPaths:
    - /sandbox
    - /tmp
  readOnly: false
```

**Note:** Filesystem policies are locked at sandbox creation. To change them, you must
recreate the sandbox.

### 4.4 Apply the Policy

⚠️ **The correct command is `policy-add`, NOT `policy update --allow-host`.** That flag
does not exist. Use the interactive preset selector:

```bash
nemoclaw <n> policy-add
```

This opens an interactive UI where you select preset policies (Telegram, Slack, GitHub,
etc.) or add custom hosts. Each preset adds the right combination of domains, methods,
and protocols for that integration.

For the full list of available policy commands and their flags:
```bash
nemoclaw <n> policy --help
# or read the canonical reference:
cat ~/.nemoclaw/source/docs/network-policy/customize-network-policy.md
```

### 4.4a `openclaw.json` is read-only inside the sandbox

The agent config file at `/sandbox/.openclaw/openclaw.json` is owned by `root` with
mode `444` — even the `sandbox` user cannot write to it. **Do not try to edit it from
inside the sandbox.** All config changes must happen on the host before sandbox start,
typically via `nemoclaw onboard`, `nemoclaw <n> policy-add`, or by re-running the wizard.

The `/sandbox/.openclaw/` directory is mostly symlinks to `/sandbox/.openclaw-data/`,
which IS writable by the sandbox user. Runtime data (credentials, logs, agent memory,
canvas, devices, telegram state) lives in `/sandbox/.openclaw-data/` and CAN be modified.

### 4.5 Verify Egress Blocking
From inside the sandbox, try to reach an unlisted host:
```bash
nemoclaw <n> connect
sandbox@<n>:~$ curl https://not-whitelisted.com
# Should be blocked
```

The blocked request will appear in `openshell term` TUI — but note that
`openshell term` only handles **device** pairing approvals, not channel pairing.
For Telegram/Slack/Discord pairing, see Phase 7.

### 4.6 Hardened Docker Image Details
The sandbox uses `ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest`.
This image has been stripped of dangerous tools (gcc, make, netcat) to reduce the
blast radius of compromise. Do not install additional tools in the sandbox unless
absolutely necessary and whitelisted in policy.
