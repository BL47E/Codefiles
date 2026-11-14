#!/usr/bin/env bash
#
# Refresh Codefiles from the live OpenCode config on this machine.
#
#   ./sync.sh          copy live skills + settings into this repo
#
# Review with `git status`/`git diff` afterwards, then commit and push.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$CONFIG_DIR/skills" ]; then
  echo "No OpenCode skills found at $CONFIG_DIR/skills — nothing to sync." >&2
  exit 1
fi

# Skills: replace the repo copy with the live one (dereference symlinks).
# NOTE: use rsync -L, NOT `cp -R dir/` — BSD cp with a trailing slash copies
# directory CONTENTS and would merge all skills into one folder.
rm -rf "$REPO_DIR/skills"
mkdir -p "$REPO_DIR/skills"
rsync -aL --exclude '.DS_Store' "$CONFIG_DIR/skills/" "$REPO_DIR/skills/"
echo "Skills synced: $(find "$REPO_DIR/skills" -name SKILL.md | wc -l | tr -d ' ') skills"

# Settings and tooling.
[ -f "$CONFIG_DIR/cli.json" ] && cp "$CONFIG_DIR/cli.json" "$REPO_DIR/"
[ -f "$CONFIG_DIR/update-skills.sh" ] && cp "$CONFIG_DIR/update-skills.sh" "$REPO_DIR/"

echo "Done. Review changes, then: git add -A && git commit -m 'sync' && git push"
