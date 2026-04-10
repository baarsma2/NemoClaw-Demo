# Phase 3: NemoClaw Installation & Onboarding

## Overview
Install NemoClaw, fix PATH issues, set environment variables, and run the onboard wizard.

## ⚠️ Critical Warnings — Read First

**1. Do NOT use `npm install -g nemoclaw`.** The npm package named `nemoclaw` is a dead
stub — it has no `bin`, no `main`, and no functionality. Installing it produces a silently
broken `nemoclaw` command. **Always use the curl installer or install from source.**

**2. Node.js 18 is too old.** Ubuntu 22.04 ships Node.js 18 by default. NemoClaw requires
Node.js 20+. Always check `node --version` BEFORE running the installer. If it shows v18
or older, install Node.js 22 via NodeSource (Step 3.1) before doing anything else.

**3. There is no `--name` flag for `nemoclaw onboard`.** The sandbox name is collected
**interactively** during the wizard. Have the desired name ready to type when prompted.
Do not try `nemoclaw onboard --name <whatever>` — it will be silently ignored and the
wizard will use a default.

**4. After install, the full NemoClaw repo lives at `~/.nemoclaw/source/`.** This is the
canonical, version-matched documentation. Whenever in doubt about commands, flags, or
behavior, read from `~/.nemoclaw/source/docs/` first instead of guessing.

## Prerequisites
- Docker running and accessible without sudo (Phase 2 complete)
- Node.js 20+ and npm 10+ (Node.js 22 recommended)
- NVIDIA API key ready

## Steps

### 3.0 Verify Node.js version FIRST
```bash
node --version
```
If this shows v18 or older, OR Node.js is not installed, proceed to Step 3.1.
If it shows v20 or higher, skip to Step 3.2.

### 3.1 Install Node.js 22 via NodeSource
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version   # should be 22.x
npm --version    # should be 10.x
```

### 3.2 Install NVIDIA OpenShell (prerequisite)
OpenShell must be installed before NemoClaw. Follow NVIDIA's OpenShell installation docs.
Verify:
```bash
openshell --version
```

### 3.3 Install NemoClaw

**Option A: One-line installer (recommended)**
```bash
curl -fsSL https://nvidia.com/nemoclaw.sh | bash
```

**Option B: From source**
```bash
git clone https://github.com/NVIDIA/NemoClaw.git
cd NemoClaw
npm install
npm run build
npm link   # makes `nemoclaw` available globally
```

**❌ Option C: `npm install -g nemoclaw` — DO NOT USE.** That npm package is a stub.
It will install a broken `nemoclaw` command that does nothing. Use Option A or B only.

### 3.3a Verify the install and discover canonical docs
After install completes, the full NemoClaw repository is at `~/.nemoclaw/source/`:

```bash
ls ~/.nemoclaw/source/docs/                # canonical documentation
ls ~/.nemoclaw/source/.agents/skills/      # 18 official NVIDIA skills
```

**Treat these as the source of truth for everything NemoClaw-specific.** When you don't
know a command flag, check `~/.nemoclaw/source/docs/reference/commands.md`. When you don't
know how to set up a feature, look in `~/.nemoclaw/source/docs/`. These docs are
version-matched to the install — your skill's reference files are not.

### 3.4 Fix PATH (critical!)
The installer places the binary at `~/.local/bin/nemoclaw`. If `nemoclaw` is not found:

```bash
export PATH=$PATH:$HOME/.local/bin
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

Verify:
```bash
which nemoclaw
nemoclaw --version
```

### 3.5 Set Environment Variables
Create the `.env` file from the planning phase values:

```bash
cat <<'EOF' > ~/nemoclaw-project/.env
NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx
NEMOCLAW_MODEL=nvidia/nemotron-3-super-120b-a12b
NEMOCLAW_SANDBOX_DIR=/var/nemoclaw/sandboxes
EOF
chmod 600 ~/nemoclaw-project/.env
```

Source it:
```bash
set -a; source ~/nemoclaw-project/.env; set +a
```

Add to `.bashrc` for persistence:
```bash
echo 'set -a; source ~/nemoclaw-project/.env; set +a' >> ~/.bashrc
```

### 3.6 Run the Onboard Wizard

**⚠️ The wizard is fully interactive. Do NOT pass `--name` or any other flag — they
do not exist and will be silently ignored.** Just run:

```bash
nemoclaw onboard
```

If you're in a session where docker group was just added, prefix with `sg docker -c`:
```bash
sg docker -c "nemoclaw onboard"
```

The wizard will prompt for:
- **Sandbox name** — type the name from the Battle Plan when prompted (e.g., `my-assistant`)
- NVIDIA API key (should auto-detect from env)
- Model selection — **use the full model ID** including prefix (e.g., `nvidia/nemotron-3-super-120b-a12b`)
  - Truncated IDs cause HTTP 403/404 errors
- Network and filesystem policy (use values from Battle Plan)

Expected success output:
```
──────────────────────────────────────────────────
Sandbox <name> (Landlock + seccomp + netns)
Model nvidia/nemotron-3-super-120b-a12b (NVIDIA Cloud API)
──────────────────────────────────────────────────
```

### 3.7 Verify Credentials Storage
```bash
ls -la ~/.nemoclaw/credentials.json   # should be mode 600
cat ~/.nemoclaw/credentials.json      # verify content (don't log this in shared terminals)
```

### 3.8 Create Project Directory
```bash
mkdir -p ~/nemoclaw-project
```

## Common Issues

**`nemoclaw: command not found`:**
PATH issue. Run `export PATH=$PATH:$HOME/.local/bin` and add to `.bashrc`.

**HTTP 403/404 during onboard model validation:**
You used a truncated model ID. Use the full prefix: `nvidia/nemotron-3-super-120b-a12b`.

**"Docker is not running" error:**
Group permissions not refreshed. Run `newgrp docker` or reconnect SSH. See Phase 2.
