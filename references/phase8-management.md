# Phase 8: Verification & Long-Term Management

## End-to-End Verification

### 8.1 Health Check Sequence
Run these in order to verify the full stack:

```bash
# 1. Sandbox is running
nemoclaw <n> status

# 2. OpenShell layer is healthy
openshell sandbox inspect <n>

# 3. Connect and test agent
nemoclaw <n> connect
sandbox@<n>:~$ openclaw agent --agent main --local -m "hello" --session-id verify

# 4. Test egress policy (should succeed)
sandbox@<n>:~$ curl -s https://build.nvidia.com -o /dev/null -w "%{http_code}"

# 5. Test egress blocking (should fail/be blocked)
sandbox@<n>:~$ curl -s https://example.com -o /dev/null -w "%{http_code}"

# 6. Check TUI for blocked device pairing requests (NOT for Telegram users)
openshell term
```

### 8.2 Test Communication Plugins (if configured)

For each plugin selected in Tier 2A, verify it's working:

**Telegram:** Send a message to your bot in Telegram. If the bot replies with a pairing
code instead of a real response, you need to approve the pairing — see Phase 7.
```bash
nemoclaw <n> logs --follow | grep telegram
```

**Slack / Discord / Webhook:** Send a test message and verify the agent responds.
Check for plugin-specific pairing flows (see Phase 7 — these may have similar issues
to Telegram).

**Outlook/Graph:** Test from inside the sandbox:
```bash
nemoclaw <n> connect
sandbox@<n>:~$ openclaw agent --agent main --local -m "list my recent emails" --session-id test
```

---

## Sandbox Logs

NemoClaw writes runtime logs inside the sandbox at `/sandbox/.openclaw-data/logs/`.
This is the canonical log location — there is no host-side aggregator by default.

To stream logs from the host:
```bash
nemoclaw <n> logs --follow
nemoclaw <n> logs --follow --level debug   # verbose
```

To inspect log files directly from inside the sandbox:
```bash
nemoclaw <n> connect
sandbox@<n>:~$ ls -la /sandbox/.openclaw-data/logs/
sandbox@<n>:~$ tail -f /sandbox/.openclaw-data/logs/<logfile>
```

If you need a host-side aggregator or audit trail, set one up yourself — NemoClaw
does not ship one. Common options: forward logs to CloudWatch/Datadog/Loki via a
sidecar, or run a cron job that periodically copies log files out of the sandbox.

---

## State Migration & Blueprints

### 8.3 Export Agent State
NemoClaw uses a blueprint system for migrating agent state across instances.
The export process strips credentials and verifies integrity:

- `MEMORY.md` — agent's long-term memory
- `SOUL.md` — agent's personality and behavioral patterns

These files persist across migrations while credentials are re-injected in the
target environment. Read `~/.nemoclaw/source/docs/workspace/backup-restore.md` for
the canonical export/import procedure.

### 8.4 Backup Strategy
```bash
# Regular backup of agent state
tar czf ~/backups/nemoclaw-state-$(date +%Y%m%d).tar.gz \
  ~/.nemoclaw/ \
  ~/nemoclaw-project/.env
```

For a full sandbox backup including agent runtime data, see the canonical guide:
```bash
cat ~/.nemoclaw/source/docs/workspace/backup-restore.md
```

---

## Ongoing Management Quick Reference

| Task | Command |
|------|---------|
| Check health | `nemoclaw <n> status` |
| Stream logs | `nemoclaw <n> logs --follow` |
| Debug logs | `nemoclaw <n> logs --follow --level debug` |
| Add egress preset (interactive) | `nemoclaw <n> policy-add` |
| Approve **device** pairing requests (NOT Telegram users) | `openshell term` |
| Start services | `nemoclaw start` |
| Stop services | `nemoclaw stop` |
| Connect to sandbox | `nemoclaw <n> connect` |
| List all sandboxes | `openshell sandbox list` |
| Inspect sandbox | `openshell sandbox inspect <n>` |
| Deploy to GPU | `nemoclaw deploy <instance> --sandbox <n>` |

For any command not listed, check `~/.nemoclaw/source/docs/reference/commands.md`
or run `<command> --help`.
