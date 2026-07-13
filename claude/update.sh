#!/usr/bin/env bash
#
# update.sh - copy the live Claude Code config from ~/.claude back into this repo.
#
# Run this after you change your theme / statusline / settings on a machine, so
# the repo picks up the edits. Then commit + push. On another machine, pull and
# run apply.sh. (We copy instead of symlink because Claude Code rewrites these
# files in place - see apply.sh for the rationale.)
#
# Idempotent: identical files are skipped; only real changes touch the repo.
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.config}"
SRC="$HOME/.claude"
DEST="$DOTFILES/claude"

# Files tracked in the repo, relative to SRC / DEST. Keep in sync with apply.sh.
FILES=(
  "settings.json"
  "statusline-command.sh"
  "themes/bamboo.json"
)

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }

changed=0
copy() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    warn "missing in ~/.claude, skipping: $src"
    return 0
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    return 0                                   # already identical
  fi
  mkdir -p "$(dirname "$dest")"
  cp -p "$src" "$dest"
  log "updated repo: ${dest#"$DOTFILES"/}"
  changed=1
}

log "Updating repo config from $SRC -> $DEST"
for f in "${FILES[@]}"; do
  copy "$SRC/$f" "$DEST/$f"
done

if [ "$changed" -eq 0 ]; then
  log "Repo already up to date."
else
  log "Repo updated. Review with 'git -C $DOTFILES diff' then commit + push."
fi
