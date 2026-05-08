#!/usr/bin/env bash
# Remove symlinks in ~/.claude/skills/ that point into this repo.
# Real files, other symlinks, and .bak.* backups are left alone.
#
# Usage:
#   bash uninstall.sh             # uninstall
#   bash uninstall.sh --dry-run   # show what would happen

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DST="$HOME/.claude/skills"

if [[ ! -d "$SKILLS_DST" ]]; then
  echo "$SKILLS_DST does not exist — nothing to do."
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "(dry-run mode — no changes will be made)"
fi

removed=0
kept=0

for entry in "$SKILLS_DST"/*; do
  [[ -e "$entry" || -L "$entry" ]] || continue
  name="$(basename "$entry")"
  if [[ -L "$entry" ]]; then
    target="$(readlink "$entry")"
    case "$target" in
      "$REPO_DIR"/*)
        echo "remove $name → $target"
        if [[ $DRY_RUN -eq 0 ]]; then
          rm "$entry"
        fi
        removed=$((removed+1))
        continue
        ;;
    esac
  fi
  echo "keep   $name (not a symlink into this repo)"
  kept=$((kept+1))
done

echo ""
echo "done. removed=$removed kept=$kept"
