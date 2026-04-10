#!/bin/bash
# nemoclaw-reset.sh
#
# Nukes a NemoClaw installation and all associated state so you can test your
# skill repeatedly from a clean slate.
#
# LEAVES INTACT:
#   - Docker, Node.js, Claude Code
#   - Your project folder and any user-created files inside it
#   - The skill itself
#   - SSH hardening (UFW, port changes, sshd_config)
#
# REMOVES (only things NemoClaw itself creates/installs):
#   - ~/.nemoclaw                                   (NemoClaw install + source repo)
#   - ~/.local/bin/nemoclaw, ~/.local/bin/openshell (binaries)
#   - ~/.npm-global/bin/nemoclaw, ~/.npm-global/lib/node_modules/nemoclaw (npm install, if any)
#   - /var/nemoclaw                                 (sandbox data, requires sudo)
#   - All NemoClaw Docker containers and images
#   - The OpenShell Docker volume
#   - ~/.config/openshell                           (OpenShell gateway state, certs, SSH config)
#   - ~/.agents/.skill-lock.json                    (NemoClaw skill lock file)
#   - NemoClaw-related lines from ~/.bashrc
#
# Usage:
#   bash ~/.claude/skills/nemoclaw-setup/references/reset.sh
#
# NOTE: This script intentionally does NOT touch your project folder or any
# user-created files (claude.md, .env, scripts, etc). If you want to clean
# those, delete them manually or re-run `nemoclaw onboard` which will overwrite
# the credentials.
#
# Safety: prompts for confirmation before doing anything destructive.

set -e

echo "⚠️  This will completely remove NemoClaw and all associated state."
echo "    Docker, Node.js, Claude Code, your project folder, and the skill"
echo "    will be left intact."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "→ Stopping NemoClaw services..."
nemoclaw stop 2>/dev/null || true

echo "→ Stopping all Docker containers..."
docker stop $(docker ps -q) 2>/dev/null || true

echo "→ Removing NemoClaw installation and source repo..."
rm -rf ~/.nemoclaw
rm -f ~/.local/bin/nemoclaw
rm -f ~/.local/bin/openshell
npm uninstall -g nemoclaw 2>/dev/null || rm -rf ~/.npm-global/lib/node_modules/nemoclaw ~/.npm-global/bin/nemoclaw 2>/dev/null || true

echo "→ Removing NemoClaw sandbox data directory..."
sudo rm -rf /var/nemoclaw 2>/dev/null || true

echo "→ Removing NemoClaw Docker containers and images..."
docker rm -f $(docker ps -aq --filter "ancestor=ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest") 2>/dev/null || true
docker rmi -f ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest 2>/dev/null || true

echo "→ Removing OpenShell Docker volume..."
docker volume rm openshell-cluster-nemoclaw 2>/dev/null || true

echo "→ Removing OpenShell config state..."
rm -rf ~/.config/openshell

echo "→ Removing NemoClaw skill lock file..."
rm -f ~/.agents/.skill-lock.json

echo "→ Cleaning .bashrc of NemoClaw entries..."
sed -i '/nemoclaw/d' ~/.bashrc 2>/dev/null || true
sed -i '/NVIDIA_API_KEY/d' ~/.bashrc 2>/dev/null || true
sed -i '/NEMOCLAW/d' ~/.bashrc 2>/dev/null || true

echo ""
echo "✅ Reset complete. Verifying clean state..."
echo ""

# Verify
FAIL=0
if command -v nemoclaw >/dev/null 2>&1; then
    echo "  ❌ nemoclaw binary still in PATH"
    FAIL=1
else
    echo "  ✅ nemoclaw binary removed"
fi

if [ -d ~/.nemoclaw ]; then
    echo "  ❌ ~/.nemoclaw still exists"
    FAIL=1
else
    echo "  ✅ ~/.nemoclaw removed"
fi

if [ -d ~/.config/openshell ]; then
    echo "  ❌ ~/.config/openshell still exists"
    FAIL=1
else
    echo "  ✅ ~/.config/openshell removed"
fi

if [ -f ~/.agents/.skill-lock.json ]; then
    echo "  ❌ skill lock file still exists"
    FAIL=1
else
    echo "  ✅ skill lock file removed"
fi

if docker images 2>/dev/null | grep -q openclaw; then
    echo "  ⚠️  openclaw Docker image still present (may be in use by another container)"
else
    echo "  ✅ openclaw Docker image removed"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "Clean state verified. NemoClaw has been fully removed."
    echo "Your project folder and any files inside it were NOT touched."
    echo ""
    echo "To re-run the skill: cd into your project folder and run 'claude'."
else
    echo "⚠️  Some items were not cleaned. Check the failures above."
fi
