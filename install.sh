#!/usr/bin/env bash
#
# Restore Codefiles onto a machine: install skills + settings into the
# OpenCode global config directory.
#
#   ./install.sh    copy skills and cli.json into place

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$CONFIG_DIR/skills"

# Skills: overlay repo skills onto the config dir. Existing skill dirs with
# the same name are replaced. This installs real files pinned at the commits
# recorded in sources.json; to track upstream instead, see sources.json ->
# how_to_update.
for name in $(ls -1 "$REPO_DIR/skills"); do
  [ -d "$REPO_DIR/skills/$name" ] || continue
  rm -rf "$CONFIG_DIR/skills/$name"
  cp -R "$REPO_DIR/skills/$name" "$CONFIG_DIR/skills/$name"
done
if [ -f "$REPO_DIR/skills/.managed.txt" ]; then
  cp "$REPO_DIR/skills/.managed.txt" "$CONFIG_DIR/skills/"
fi
echo "Installed $(find "$REPO_DIR/skills" -name SKILL.md | wc -l | tr -d ' ') skills to $CONFIG_DIR/skills"

# Settings.
cp "$REPO_DIR/cli.json" "$CONFIG_DIR/cli.json"
echo "Installed cli.json to $CONFIG_DIR"

# Provenance manifest: where each skill came from + pinned commits.
if [ -f "$REPO_DIR/sources.json" ]; then
  cp "$REPO_DIR/sources.json" "$CONFIG_DIR/skills/.sources.json"
  echo "Installed provenance manifest to $CONFIG_DIR/skills/.sources.json"
fi

echo "Note: service.json (secrets) is intentionally not in this repo."
echo "Note: to update skills from upstream later, follow sources.json -> how_to_update."
