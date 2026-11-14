#!/usr/bin/env bash
#
# Refresh the global OpenCode skills from upstream repositories.
#
#   ./update-skills.sh          install/update the stable skill sets
#   ./update-skills.sh --all    also include Matt Pocock's in-progress skills
#
# Skills are copied into ~/.config/opencode/skills/<id>/ so OpenCode discovers
# them in every project. The upstream repos are shallow clones kept under
# ~/.config/opencode/vendor/skills/. Anything inside a managed skill directory
# is overwritten on each run; edit the vendor copies only to experiment, or
# copy a skill to a new ID if you want to own the changes.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SKILLS_DIR="$CONFIG_DIR/skills"
VENDOR_DIR="$CONFIG_DIR/vendor/skills"
MANAGED_FILE="$SKILLS_DIR/.managed.txt"

MATTPOCOCK_REPO="https://github.com/mattpocock/skills.git"
ANTHROPIC_REPO="https://github.com/anthropics/skills.git"

MATTPOCOCK_SETS=(engineering productivity misc)
MATTPOCOCK_EXPERIMENTAL_SET=in-progress

usage() {
  cat <<'EOF'
Usage: update-skills.sh [--all]

  --all    also install Matt Pocock's in-progress skills
  -h       show this help

Installs into ~/.config/opencode/skills (global, every project).
EOF
}

include_experimental=0
case "${1:-}" in
  --all) include_experimental=1 ;;
  -h | --help) usage; exit 0 ;;
  "") ;;
  *)
    echo "unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

sync_repo() {
  local dest=$1 url=$2
  if [ -d "$dest/.git" ]; then
    echo "Updating $(basename "$dest")"
    git -C "$dest" pull --ff-only --quiet
  else
    echo "Cloning $(basename "$dest")"
    git clone --depth 1 --quiet "$url" "$dest"
  fi
}

installed=()

install_skill() {
  local src=$1 id dst
  id=$(basename "$src")
  dst="$SKILLS_DIR/$id"
  mkdir -p "$dst"
  rsync -a --delete "$src/" "$dst/"
  installed+=("$id")
}

mkdir -p "$SKILLS_DIR" "$VENDOR_DIR"

sync_repo "$VENDOR_DIR/mattpocock" "$MATTPOCOCK_REPO"
sync_repo "$VENDOR_DIR/anthropic" "$ANTHROPIC_REPO"

sets=("${MATTPOCOCK_SETS[@]}")
if [ "$include_experimental" -eq 1 ]; then
  sets+=("$MATTPOCOCK_EXPERIMENTAL_SET")
fi

for set in "${sets[@]}"; do
  for skill_md in "$VENDOR_DIR"/mattpocock/skills/"$set"/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    install_skill "$(dirname "$skill_md")"
  done
done

# skills/template is a starting point for new skills, not a usable skill.
for skill_md in "$VENDOR_DIR"/anthropic/skills/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  install_skill "$(dirname "$skill_md")"
done

# Drop skills that were installed by a previous run but are gone upstream.
if [ -f "$MANAGED_FILE" ]; then
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    keep=0
    for new_id in "${installed[@]}"; do
      if [ "$id" = "$new_id" ]; then
        keep=1
        break
      fi
    done
    if [ "$keep" -eq 0 ] && [ -d "$SKILLS_DIR/$id" ]; then
      rm -rf "$SKILLS_DIR/$id"
      echo "Removed stale skill: $id"
    fi
  done <"$MANAGED_FILE"
fi

printf '%s\n' "${installed[@]}" | sort >"$MANAGED_FILE"

echo
echo "Installed ${#installed[@]} skills into $SKILLS_DIR"
