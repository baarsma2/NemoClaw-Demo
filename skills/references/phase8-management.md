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

# 6. Check TUI for blocked request
openshell term
```

### 8.2 Test Telegram Bridge (if configured)
Send a test message to your bot and verify response.

### 8.3 Test Sub-Agents (if configured)
From inside the sandbox, trigger a sub-agent spawn and verify it completes.

---

## Audit Logging

### 8.4 Set Up Audit Directory
```bash
mkdir -p ~/ta-agent/logs
touch ~/ta-agent/logs/audit.json
```

The audit log tracks:
- Every agent action
- Token counts per action
- Approval/denial status for egress requests
- Timestamps for forensic analysis

### 8.5 Monitor Audit Logs
```bash
tail -f ~/ta-agent/logs/audit.json | jq .
```

---

## Automated Weekly Reports

### 8.6 Create Summary Script
Create `~/nemoclaw-project/weekly_summary.py`:

```python
#!/usr/bin/env python3
"""Analyze agent performance and cost from audit logs."""
import json
from pathlib import Path
from datetime import datetime, timedelta

AUDIT_LOG = Path.home() / "ta-agent" / "logs" / "audit.json"

def generate_summary():
    # Read and analyze the last 7 days of audit entries
    # Calculate: total actions, token usage, cost estimate, blocked requests
    pass

if __name__ == "__main__":
    generate_summary()
```

### 8.7 Configure Crontab
```bash
crontab -e
# Add:
0 9 * * 1 /usr/bin/python3 ~/nemoclaw-project/weekly_summary.py >> ~/ta-agent/logs/weekly.log 2>&1
```

---

## State Migration & Blueprints

### 8.8 Export Agent State
NemoClaw uses a blueprint system for migrating agent state across instances.
The export process strips credentials and verifies integrity:

- `MEMORY.md` — agent's long-term memory
- `SOUL.md` — agent's personality and behavioral patterns

These files persist across migrations while credentials are re-injected in the
target environment.

### 8.9 Backup Strategy
```bash
# Regular backup of agent state (add to crontab)
tar czf ~/backups/nemoclaw-state-$(date +%Y%m%d).tar.gz \
  ~/.nemoclaw/ \
  ~/ta-agent/logs/ \
  ~/nemoclaw-project/.env
```

---

## Ongoing Management Quick Reference

| Task | Command |
|------|---------|
| Check health | `nemoclaw <n> status` |
| Stream logs | `nemoclaw <n> logs --follow` |
| Debug logs | `nemoclaw <n> logs --follow --level debug` |
| Add egress host | `nemoclaw <n> policy update --allow-host <domain>` |
| Approve blocked request | `openshell term` (TUI) |
| Start services | `nemoclaw start` |
| Stop services | `nemoclaw stop` |
| Connect to sandbox | `nemoclaw <n> connect` |
| List all sandboxes | `openshell sandbox list` |
| Deploy to GPU | `nemoclaw deploy <instance> --sandbox <n>` |
