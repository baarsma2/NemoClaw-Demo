# Phase 6: Sub-Agents & Orchestration

## Overview
Configure OpenClaw for multi-agent workflows. Sub-agents are background worker sessions
spawned by a main agent for parallel task execution.

## Architecture

| Component | Level | Authority |
|-----------|-------|-----------|
| Main Agent | Depth 0 | Full authority, spawns depth 1 |
| Orchestrator | Depth 1 | Manages workers, spawns depth 2 |
| Worker Agent | Depth 2 | Execution-only, no spawning |

## Steps

### 6.1 Configure openclaw.json for Sub-Agents

The key settings in `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "maxConcurrent": 8,
      "runTimeoutSeconds": 900
    },
    "list": {
      "main": {
        "maxSpawnDepth": 2,
        "allowAgents": ["*"],
        "tools": ["sessions_spawn"]
      }
    }
  }
}
```

### 6.2 CRITICAL: allowAgents Placement

**This is the most common configuration mistake.** The `allowAgents` list MUST be
defined inside the specific agent entry in `agents.list`, NOT in `agents.defaults`.

Wrong (will silently fail):
```json
{
  "agents": {
    "defaults": {
      "allowAgents": ["*"]    // ← WRONG LOCATION
    }
  }
}
```

Correct:
```json
{
  "agents": {
    "list": {
      "main": {
        "allowAgents": ["*"]  // ← CORRECT: per-agent
      }
    }
  }
}
```

### 6.3 Spawn Depth Configuration

- `maxSpawnDepth: 1` — Sub-agents cannot spawn their own children (default)
- `maxSpawnDepth: 2` — Enables the orchestrator pattern (main → orchestrator → workers)

For complex workflows, set to 2. For simple delegation, 1 is sufficient.

### 6.4 Sandbox Inheritance Guard

When running inside a NemoClaw sandbox, all sub-agents automatically inherit the
sandbox's security policies. A sub-agent spawned from a sandboxed session is forced
into a sandboxed environment — it cannot escape isolation through a child process.

This is enforced by the runtime and requires no additional configuration.

### 6.5 Verify Sub-Agent Configuration

Inside the sandbox:
```bash
openclaw agent --agent main --local -m "spawn a sub-agent to check the current time" --session-id test
```

Check logs for successful spawn:
```bash
nemoclaw <n> logs --follow | grep "sessions_spawn"
```

### 6.6 Tiered Model Routing (Module C)

This section applies if Module C (tiered routing) was selected in Tier 2B.
It works with or without sub-agents — the difference is how the tiers are used.

**With sub-agents (Module B + C):** Each tier maps to a named agent in `agents.list`.
The router agent classifies requests and delegates to the appropriate specialist:

```json
{
  "agents": {
    "list": {
      "router": {
        "model": "gpt-4o-mini",
        "allowAgents": ["researcher", "coder"],
        "description": "Classifies incoming requests and delegates"
      },
      "researcher": {
        "model": "nvidia/nemotron-3-super-120b-a12b",
        "description": "Deep research and analysis"
      },
      "coder": {
        "model": "claude-sonnet-4-6",
        "description": "Code generation and debugging"
      }
    }
  }
}
```

**Without sub-agents (Module C only):** Use a single `main` agent but configure
model overrides for different task types. The agent switches models based on
complexity without spawning separate sessions:

```json
{
  "agents": {
    "list": {
      "main": {
        "model": "nvidia/nemotron-3-super-120b-a12b",
        "modelOverrides": {
          "simple": "gpt-4o-mini",
          "coding": "claude-sonnet-4-6",
          "executive": "claude-opus-4-6"
        }
      }
    }
  }
}
```

**Cost tier reference:**

| Tier | Use case | Example model | Cost |
|------|----------|--------------|------|
| Lookup | Simple factual queries | gpt-4o-mini | Lowest |
| Analytical | Summaries, comparisons | nvidia/nemotron-3-super-120b-a12b | Low-Medium |
| Coding | Debugging, code gen | claude-sonnet-4-6 | Medium-High |
| Executive | Strategy, multi-phase plans | claude-opus-4-6 | Highest |

This can reduce costs by 80-90% compared to using a single high-reasoning model.

## Troubleshooting

**"allowed: none" on sub-agents:**
`allowAgents` is in `agents.defaults` instead of the specific agent in `agents.list`.
Move it to the agent that needs to use `sessions_spawn`.

**Sub-agents timing out:**
Increase `runTimeoutSeconds` (default 900 = 15 minutes). For long research tasks,
consider 1800 or higher.

**Sub-agents not sandboxed:**
This should not happen with NemoClaw. If it does, check that the sandbox inheritance
guard is active by inspecting the sub-agent's environment variables.
