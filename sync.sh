#!/usr/bin/env bash
#
# Refresh Codefiles from the live OpenCode config on this machine.
#
#   ./sync.sh    copy live skills + settings into this repo and regenerate
#                sources.json (the provenance manifest)
#
# Review with `git status` / `git diff` afterwards, then commit and push.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_ROOT="${T3_SOURCES_ROOT:-$HOME/.t3/skills-sources}"
MANIFEST="$REPO_DIR/sources.json"

if [ ! -d "$CONFIG_DIR/skills" ]; then
  echo "No OpenCode skills found at $CONFIG_DIR/skills — nothing to sync." >&2
  exit 1
fi

# Skills: replace the repo copy with the live one (dereference symlinks).
# NOTE: rsync -L, NOT `cp -R dir/` — BSD cp with a trailing slash copies
# directory CONTENTS and would merge all skills into one folder.
rm -rf "$REPO_DIR/skills"
mkdir -p "$REPO_DIR/skills"
rsync -aL --exclude '.DS_Store' --exclude '.sources.json' \
  "$CONFIG_DIR/skills/" "$REPO_DIR/skills/"
echo "Skills synced: $(find "$REPO_DIR/skills" -name SKILL.md | wc -l | tr -d ' ') skills"

# Settings.
if [ -f "$CONFIG_DIR/cli.json" ]; then
  cp "$CONFIG_DIR/cli.json" "$REPO_DIR/"
fi

# ---------------------------------------------------------------------------
# Provenance manifest: record which upstream repo and path each skill comes
# from, pinned at the exact commit currently installed.
# ---------------------------------------------------------------------------
if [ -d "$SOURCES_ROOT" ]; then
  skills_tmp=$(mktemp); clones_tmp=$(mktemp); seen_tmp=$(mktemp)
  trap 'rm -f "$skills_tmp" "$clones_tmp" "$seen_tmp"' EXIT
  for name in $(ls -1 "$CONFIG_DIR/skills" 2>/dev/null); do
    target=$(readlink "$CONFIG_DIR/skills/$name" 2>/dev/null) || continue
    case "$target" in
      "$SOURCES_ROOT"/*/*) ;;
      *) continue ;;
    esac
    rest="${target#"$SOURCES_ROOT"/}"
    clone="${rest%%/*}"
    rel="${rest#*/}"
    printf '    "%s": {"source": "%s", "path": "%s"}\n' \
      "$name" "$clone" "$rel" >>"$skills_tmp"
    if ! grep -qx "$clone" "$seen_tmp" 2>/dev/null; then
      printf '%s\n' "$clone" >>"$seen_tmp"
      cpath="$SOURCES_ROOT/$clone"
      printf '    "%s": {"repo": "%s", "branch": "%s", "commit": "%s", "commit_date": "%s", "local_clone": "%s"}\n' \
        "$clone" \
        "$(git -C "$cpath" remote get-url origin 2>/dev/null || echo unknown)" \
        "$(git -C "$cpath" branch --show-current 2>/dev/null || echo unknown)" \
        "$(git -C "$cpath" rev-parse HEAD 2>/dev/null || echo unknown)" \
        "$(git -C "$cpath" log -1 --format=%cI 2>/dev/null || echo unknown)" \
        "$cpath" >>"$clones_tmp"
    fi
  done
  if [ -s "$skills_tmp" ]; then
    {
      printf '{\n'
      printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf '  "what": "Provenance for every skill in skills/: which upstream repo and path it came from, pinned at the installed commit.",\n'
      printf '  "how_to_update": "Pull each repo listed in sources to its local_clone (git pull), re-run the installer that symlinks skills into the config dir (on the original machine: node ~/.t3/skills-sources/update-skills.js), then run sync.sh in this repo and commit the result.",\n'
      printf '  "sources": {\n'
      awk 'NR>1{printf ",\n"}{printf "%s",$0}' "$clones_tmp"
      printf '\n  },\n  "skills": {\n'
      awk 'NR>1{printf ",\n"}{printf "%s",$0}' "$skills_tmp"
      printf '\n  }\n}\n'
    } >"$MANIFEST"
    echo "Manifest: $(wc -l <"$skills_tmp" | tr -d ' ') skills from $(wc -l <"$seen_tmp" | tr -d ' ') sources -> $MANIFEST"
    # Keep a copy where live AI sessions can find it.
    cp "$MANIFEST" "$CONFIG_DIR/skills/.sources.json"
  else
    echo "Warning: no skills symlinked under $SOURCES_ROOT — kept existing sources.json." >&2
  fi
else
  echo "Warning: $SOURCES_ROOT not found — kept existing sources.json." >&2
fi

echo "Done. Review changes, then: git add -A && git commit -m 'sync' && git push"
