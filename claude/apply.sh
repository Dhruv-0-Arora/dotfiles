#!/usr/bin/env bash
#
# apply.sh - copy the tracked Claude Code config from this repo into ~/.claude.
#
# We COPY rather than symlink on purpose: Claude Code rewrites settings.json in
# place (changing theme/model via /config, toggling plugins, ...), and tools
# that save atomically would clobber a symlink with a real file. So the flow is:
#   - apply.sh   repo  -> ~/.claude   (this script; run on a new machine / after a pull)
#   - update.sh  ~/.claude -> repo    (run after you tweak settings, before committing)
#
# Idempotent: identical files are skipped, and anything it would overwrite with
# different content is backed up first.
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.config}"
SRC="$DOTFILES/claude"
DEST="$HOME/.claude"

# Files tracked in the repo, relative to SRC / DEST. Keep in sync with update.sh.
FILES=(
  "settings.json"
  "statusline-command.sh"
  "themes/bamboo.json"
)

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }

# symlink SRC -> DEST, backing up whatever is already at DEST (unless it is
# already a symlink resolving to the same place).
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ] || \
       [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src" 2>/dev/null)" ]; then
      return 0                                 # already correct
    fi
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local bak="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    warn "backing up existing $dest -> $bak"
    mv "$dest" "$bak"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  log "linked $dest -> $src"
}

# copy SRC file -> DEST file, backing up an existing DEST with different content.
copy() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    warn "missing in repo, skipping: $src"
    return 0
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    return 0                                   # already identical
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local bak="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    warn "backing up existing $dest -> $bak"
    cp -p "$dest" "$bak"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -p "$src" "$dest"
  log "applied $dest"
}

log "Applying Claude config from $SRC -> $DEST"
for f in "${FILES[@]}"; do
  copy "$SRC/$f" "$DEST/$f"
done

# Claude Code project memory for the dotfiles repo. Unlike the files above this
# is SYMLINKED, not copied: Claude Code writes to it continuously and we want
# those writes to land in the repo. Claude names project dirs by encoding the
# project path with '/' and '.' both replaced by '-'.
proj_enc="$(printf '%s' "$DOTFILES" | tr '/.' '--')"
link "$SRC/memory" "$HOME/.claude/projects/$proj_enc/memory"

log "Done. Restart Claude Code (or run /config) to pick up changes."
