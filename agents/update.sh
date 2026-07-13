#!/usr/bin/env bash
#
# update.sh - snapshot the live ~/.agents hub back into this repo.
#
# The hub is harness-independent: instruction files (AGENTS.md, OPINIONS.md,
# VOICE.md) and every skill under ~/.agents/skills/. install-agents.sh sets the
# hub up FROM the repo (repo -> ~/.agents via symlinks); this script is the
# reverse capture (~/.agents -> repo), so skills that were installed live
# (bunx/uv, e.g. gh-axi, lavish, chrome-devtools-axi, graphify) get committed.
#
# What it does with each item in ~/.agents:
#   - a symlink that already resolves into this repo  -> skipped (already tracked;
#     e.g. AGENTS.md, run-gws, and the code-quality submodule)
#   - a name in the IGNORE list                       -> skipped
#   - a real file/dir                                 -> copied into the repo
#
# After it runs, review with `git -C ~/.config status` and commit.
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.config}"
HUB="$HOME/.agents"
REPO="$DOTFILES/agents"

# Skills NOT copied into the (public) dotfiles repo - not from public sources.
# Add or remove names here to change what gets tracked.
IGNORE=(
  "astute"
  "gcal-axi"
)

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
info() { printf '    %s\n' "$*"; }

# true if $1 is a symlink whose target resolves to somewhere inside $DOTFILES.
points_into_repo() {
  [ -L "$1" ] || return 1
  local tgt; tgt="$(readlink -f "$1" 2>/dev/null || true)"
  case "$tgt" in "$DOTFILES"/*) return 0 ;; *) return 1 ;; esac
}

in_ignore() {
  local name="$1"
  for n in "${IGNORE[@]}"; do [ "$n" = "$name" ] && return 0; done
  return 1
}

changed=0

# --- 1. Instruction files ------------------------------------------------
log "Instruction files (~/.agents/*.md -> repo)"
for md in AGENTS.md OPINIONS.md VOICE.md; do
  src="$HUB/$md"
  [ -e "$src" ] || { warn "missing in hub: $md"; continue; }
  if points_into_repo "$src"; then
    info "skip $md (symlink into repo - already tracked)"
    continue
  fi
  if [ -f "$REPO/$md" ] && cmp -s "$src" "$REPO/$md"; then
    info "skip $md (unchanged)"
    continue
  fi
  cp -p "$src" "$REPO/$md"
  info "copied $md"
  changed=1
done

# --- 2. Skills -----------------------------------------------------------
log "Skills (~/.agents/skills/ -> repo, excluding symlinks + ignore-list)"
mkdir -p "$REPO/skills"
for skill_dir in "$HUB"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  src="${skill_dir%/}"

  if points_into_repo "$src"; then
    info "skip $name (symlink into repo - already tracked)"
    continue
  fi
  if in_ignore "$name"; then
    info "skip $name (ignore-list)"
    continue
  fi

  dest="$REPO/skills/$name"
  mkdir -p "$dest"
  # Mirror the live skill into the repo, dropping VCS + macOS cruft. -i itemizes
  # what actually changed; ignore bare directory-mtime lines (.d..t...) so we
  # only report a real content change.
  out="$(rsync -a --delete -i \
    --exclude '.git' --exclude '.git/' \
    --exclude '._*' --exclude '.DS_Store' \
    "$src/" "$dest/" | grep -Ev '^\.d\.\.t' || true)"
  if [ -n "$out" ]; then
    info "synced $name"
    changed=1
  else
    info "skip $name (unchanged)"
  fi
done

# --- 3. Summary ----------------------------------------------------------
if [ "$changed" -eq 0 ]; then
  log "Repo already up to date with the hub."
else
  log "Hub captured into the repo."
  info "Review + commit:"
  info "  git -C $DOTFILES status agents/"
  info "  git -C $DOTFILES add agents/ && git -C $DOTFILES commit"
fi
