#!/bin/bash
# nemoclaw-reset.sh
#
# Nukes a NemoClaw installation and all associated state so you can test your
# skill repeatedly from a clean slate. LEAVES INTACT: Docker, Node.js, Claude
# Code, your project folder, the skill itself, your .bashrc PATH entries.
#
# REMOVES:
#   - ~/.nemoclaw (NemoClaw install + source repo)
#   - ~/.local/bin/nemoclaw (binary)
#   - /var/nemoclaw (sandbox data)
#   - All NemoClaw Docker containers and images
#   - The OpenShell Docker volume
#   - Artifact files created during setup debugging:
#       * ~/nemoclaw-project/.env
#       * ~/nemoclaw-project/approve-pairing.js (if created)
#       * ~/nemoclaw-project/node_modules/ (if ws was installed for WebSocket debug)
#       * ~/nemoclaw-project/host-tree.txt, tree-*.txt (diagnostic dumps)
#       * ~/nemoclaw-project/postmortem.md (if created)
#   - .bashrc entries for NemoClaw PATH and env vars
#
# Usage:
#   bash ~/.claude/skills/nemoclaw-setup/references/reset.sh
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

echo "→ Removing NemoClaw sandbox data directory..."
sudo rm -rf /var/nemoclaw 2>/dev/null || true

echo "→ Removing NemoClaw Docker containers and images..."
docker rm -f $(docker ps -aq --filter "ancestor=ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest") 2>/dev/null || true
docker rmi -f ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest 2>/dev/null || true

echo "→ Removing OpenShell Docker volume..."
docker volume rm openshell-cluster-nemoclaw 2>/dev/null || true

echo "→ Cleaning up project folder artifacts..."
rm -f ~/nemoclaw-project/.env
rm -f ~/nemoclaw-project/approve-pairing.js
rm -rf ~/nemoclaw-project/node_modules
rm -f ~/nemoclaw-project/host-tree.txt
rm -f ~/nemoclaw-project/tree-*.txt
rm -f ~/nemoclaw-project/postmortem.md
rm -rf ~/nemoclaw-project/.claude

echo "→ Cleaning .bashrc of NemoClaw entries..."
sed -i '/\.local\/bin/d' ~/.bashrc 2>/dev/null || true
sed -i '/nemoclaw/d' ~/.bashrc 2>/dev/null || true
sed -i '/NVIDIA_API_KEY/d' ~/.bashrc 2>/dev/null || true
sed -i '/NEMOCLAW/d' ~/.bashrc 2>/dev/null || true
sed -i '/nemoclaw-project\/.env/d' ~/.bashrc 2>/dev/null || true

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

if [ -f ~/nemoclaw-project/.env ]; then
    echo "  ❌ ~/nemoclaw-project/.env still exists"
    FAIL=1
else
    echo "  ✅ ~/nemoclaw-project/.env removed"
fi

if docker images 2>/dev/null | grep -q openclaw; then
    echo "  ⚠️  openclaw Docker image still present (may be in use by another container)"
else
    echo "  ✅ openclaw Docker image removed"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "Clean state verified. You can now:"
    echo "  1. cd ~/nemoclaw-project"
    echo "  2. claude"
    echo "  3. Run the skill from scratch"
else
    echo "⚠️  Some items were not cleaned. Check the failures above."
fi
