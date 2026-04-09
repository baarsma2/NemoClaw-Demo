nemoclaw-setup
Claude Code skill for deploying NVIDIA NemoClaw sandboxed AI agents on any Linux server.
Install
bashnpx skills add <your-github-org>/nemoclaw-setup
What it does
Interactive wizard that handles the full NemoClaw lifecycle:

Security hardening (SSH, UFW, cloud firewall)
Docker & cgroup v2 configuration
NemoClaw installation & onboarding
Sandbox policy enforcement (Landlock + seccomp + netns)
Networking (SSH tunnels for Control UI)
Communication plugins (Telegram, Slack, Discord, Outlook, webhooks)
Verification & ongoing management

How it works

Asks 6 essential setup questions
Asks which communication plugins you want
Produces a Battle Plan for confirmation
Executes phases in order with verification at each step

Compatibility

Any Ubuntu 22.04+ host (AWS EC2, Azure VM, Hostinger, DigitalOcean, bare metal)
Claude Code, Cursor, Codex CLI, Gemini CLI, and other agents supporting the Agent Skills spec

Structure
skills/nemoclaw-setup/
├── SKILL.md
└── references/
    ├── phase1-security.md
    ├── phase2-docker.md
    ├── phase3-install.md
    ├── phase4-sandbox.md
    ├── phase5-networking.md
    ├── phase6-subagents.md
    ├── phase7-integrations.md
    ├── phase8-management.md
    └── troubleshooting.md