#!/usr/bin/env bash
# Install personal Claude Code skills by symlinking ./skills/* into ~/.claude/skills/.
# Conflicts are backed up to <name>.bak.<timestamp> rather than silently overwritten.
#
# Usage:
#   bash install.sh             # install
#   bash install.sh --dry-run   # show what would happen, don't change anything

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"
TS="$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "error: $SKILLS_SRC does not exist" >&2
  exit 1
fi

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

if [[ $DRY_RUN -eq 1 ]]; then
  echo "(dry-run mode — no changes will be made)"
fi

mkdir -p "$SKILLS_DST"

installed=0
skipped=0
backed_up=0

for src in "$SKILLS_SRC"/*/; do
  name="$(basename "$src")"
  src_abs="${src%/}"
  dst="$SKILLS_DST/$name"

  if [[ -L "$dst" ]]; then
    current="$(readlink "$dst")"
    if [[ "$current" == "$src_abs" ]]; then
      echo "skip   $name (already symlinked correctly)"
      skipped=$((skipped+1))
      continue
    fi
    echo "backup $name (existing symlink → $current)"
    run "mv \"$dst\" \"$dst.bak.$TS\""
    backed_up=$((backed_up+1))
  elif [[ -e "$dst" ]]; then
    echo "backup $name (existing file/dir)"
    run "mv \"$dst\" \"$dst.bak.$TS\""
    backed_up=$((backed_up+1))
  fi

  echo "link   $name → $src_abs"
  run "ln -s \"$src_abs\" \"$dst\""
  installed=$((installed+1))
done

echo ""
echo "done. installed=$installed skipped=$skipped backed_up=$backed_up"
if [[ $backed_up -gt 0 && $DRY_RUN -eq 0 ]]; then
  echo "backups saved with suffix .bak.$TS in $SKILLS_DST"
fi
