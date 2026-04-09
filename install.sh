#!/usr/bin/env bash
# Install the NemoClaw-Setup skill into Claude Code's skills directory.
# Usage: bash install.sh

set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/NemoClaw-Setup"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing NemoClaw-Setup skill to ${SKILL_DIR} ..."

mkdir -p "${SKILL_DIR}/references"

cp "${REPO_DIR}/SKILL.md"             "${SKILL_DIR}/SKILL.md"
cp "${REPO_DIR}/references/"*.md      "${SKILL_DIR}/references/"

echo "Done. Skill installed at ${SKILL_DIR}"
echo "Restart Claude Code (or reload skills) for it to take effect."#!/usr/bin/env bash
# Install the NemoClaw-Setup skill into Claude Code's skills directory.
# Usage: bash install.sh

set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/NemoClaw-Setup"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing NemoClaw-Setup skill to ${SKILL_DIR} ..."

mkdir -p "${SKILL_DIR}/references"

cp "${REPO_DIR}/SKILL.md"             "${SKILL_DIR}/SKILL.md"
cp "${REPO_DIR}/references/"*.md      "${SKILL_DIR}/references/"

echo "Done. Skill installed at ${SKILL_DIR}"
echo "Restart Claude Code (or reload skills) for it to take effect."