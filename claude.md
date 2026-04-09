# Building a Claude Code Skill — Reference Guide

This documents the correct structure and process for building a publishable Claude Code skill from scratch, based on the agentskills.io spec and observed CLI behavior.

---

## How Skills Work

A skill is a Markdown reference guide that Claude loads on demand to guide behavior. Skills are installed from GitHub repos into `~/.claude/skills/<skill-name>/` on the user's machine.

The skills CLI maps repo content as follows:

| Repo path | Installed path |
|-----------|----------------|
| `SKILL.md` (root) | `~/.claude/skills/<name>/SKILL.md` |
| `skills/references/foo.md` | `~/.claude/skills/<name>/references/foo.md` |
| `skills/examples/bar.ts` | `~/.claude/skills/<name>/examples/bar.ts` |

**Key insight:** The `skills/` folder in the repo is the supporting files directory. Its contents are mapped directly into the installed skill folder (the `skills/` prefix is stripped). The root `SKILL.md` becomes the main skill file.

---

## Repo Structure

```
SKILL.md                        # Main skill file — required at repo root
skills/                         # Supporting files (optional)
  references/
    topic-a.md                  # Heavy reference docs (100+ lines each)
    topic-b.md
  examples/
    example.ts                  # Reusable code examples/tools
.gitignore                      # Exclude claude.md, CLAUDE.md, .env, etc.
```

Do NOT put `README.md` or `claude.md` in the repo (or gitignore them) — they are project-local and not part of the published skill.

---

## SKILL.md Structure

```markdown
---
name: my-skill-name            # letters, numbers, hyphens only — no special chars
description: Use when [specific triggering conditions and symptoms]
---

# Skill Title

Brief overview — core principle in 1-2 sentences.

## When to Use
- Bullet list of symptoms/situations that trigger this skill
- When NOT to use

## [Core content — steps, patterns, quick reference tables]

## Key Warnings
- Critical gotchas

## Common Mistakes
| Mistake | Fix |
|---------|-----|
```

### Frontmatter Rules
- `name`: letters, numbers, hyphens only (no parentheses, spaces, special chars)
- `description`: starts with "Use when..." — describes **triggering conditions only**, never summarizes the skill's workflow. Max ~500 chars. Written in third person.
- Max 1024 characters total in frontmatter

### Description Anti-Pattern
The description is what Claude reads to decide whether to load the skill. If it summarizes the workflow, Claude follows the description instead of reading the full skill body.

```yaml
# BAD — summarizes workflow, Claude may shortcut
description: Use when deploying NemoClaw — follow 8 phases from SSH hardening to verification

# GOOD — triggering conditions only
description: Use when deploying or configuring NemoClaw sandboxed AI agent environments on Linux VMs
```

---

## Reference Files (skills/references/)

Use separate reference files when a topic exceeds ~100 lines. Keep them focused — one topic per file.

In `SKILL.md`, reference them by their **installed path** (without the `skills/` prefix):

```markdown
Read `references/phase1-security.md` for SSH hardening steps.
```

NOT `skills/references/phase1-security.md` — that's the repo path, not the installed path.

---

## .gitignore

Always exclude project-local files:

```
# Project-local — not part of the published skill
claude.md
CLAUDE.md
.env
*.env
*.log

# OS / editor artifacts
.DS_Store
Thumbs.db
.vscode/
.idea/
```

---

## Publishing Checklist

- [ ] `SKILL.md` exists at repo root with valid `name` and `description` frontmatter
- [ ] `name` uses only letters, numbers, hyphens
- [ ] `description` starts with "Use when..." and describes triggering conditions only
- [ ] Supporting files are in `skills/` (not at root alongside SKILL.md)
- [ ] Reference paths in SKILL.md use `references/...` not `skills/references/...`
- [ ] `claude.md`, `README.md`, `.env` are gitignored
- [ ] Empty placeholder files removed (e.g. empty `skills/SKILL.md`)

---

## Install Command (for users)

```bash
claude skills install baarsma2/NemoClaw-Demo
```
