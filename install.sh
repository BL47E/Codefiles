#!/usr/bin/env bash
#
# Restore Codefiles onto a machine: install skills + settings into the
# OpenCode global config directory.
#
#   ./install.sh       copy skills, cli.json, update-skills.sh into place

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$CONFIG_DIR/skills"

# Skills: overlay repo skills onto the config dir. Existing skill dirs with
# the same name are replaced.
for entry in "$REPO_DIR/skills"/*/; do
  name="$(basename "$entry")"
  rm -rf "$CONFIG_DIR/skills/$name"
  cp -R "$entry" "$CONFIG_DIR/skills/$name"
done
[ -f "$REPO_DIR/skills/.managed.txt" ] && cp "$REPO_DIR/skills/.managed.txt" "$CONFIG_DIR/skills/"
echo "Installed $(find "$REPO_DIR/skills" -name SKILL.md | wc -l | tr -d ' ') skills to $CONFIG_DIR/skills"

# Settings and tooling.
cp "$REPO_DIR/cli.json" "$CONFIG_DIR/cli.json"
cp "$REPO_DIR/update-skills.sh" "$CONFIG_DIR/update-skills.sh"
chmod +x "$CONFIG_DIR/update-skills.sh"

echo "Installed cli.json and update-skills.sh to $CONFIG_DIR"
echo "Note: service.json (secrets) is intentionally not in this repo."
echo "Note: run ./update-skills.sh to rebuild the vendor/ skill sources."
