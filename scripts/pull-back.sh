#!/usr/bin/env bash
# Copy a skill you tweaked inside a project back into this repo.
# Usage: scripts/pull-back.sh <project-dir> <skill-name>
set -euo pipefail

project="${1:?usage: pull-back.sh <project-dir> <skill-name>}"
skill="${2:?usage: pull-back.sh <project-dir> <skill-name>}"
repo="$(cd "$(dirname "$0")/.." && pwd)"

for dir in "$project/.agents/skills/$skill" "$project/.claude/skills/$skill" "$project/.codex/skills/$skill"; do
  if [[ -f "$dir/SKILL.md" ]]; then
    mkdir -p "$repo/skills/$skill"
    # -L follows symlinks, --delete drops files removed in the project.
    rsync -aL --delete "$dir/" "$repo/skills/$skill/"
    echo "Copied $dir -> skills/$skill"
    git -C "$repo" status --short "skills/$skill"
    exit 0
  fi
done

echo "No $skill/SKILL.md found under $project/.agents, .claude, or .codex skills." >&2
exit 1
