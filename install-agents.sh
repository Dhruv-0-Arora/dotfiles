#!/usr/bin/env bash
#
# install-agents.sh - sync the agentic setup (skills, instruction files,
# memory) from the dotfiles repo onto this machine.
#
# Layout it maintains:
#   ~/.agents/                        hub shared by every coding agent
#     AGENTS.md, VOICE.md, OPINIONS.md  -> symlinks into $DOTFILES/agents/
#     skills/<name>                     -> repo-managed skills are symlinks;
#                                          bunx-installed skills are real dirs
#   ~/AGENTS.md, ~/VOICE.md, ~/OPINIONS.md -> symlinks into ~/.agents/
#   ~/.claude/CLAUDE.md, ~/.gemini/GEMINI.md -> ~/.agents/AGENTS.md
#   ~/.claude/skills/<name>, ~/.gemini/skills/<name> -> ~/.agents/skills/<name>
#
# Everything is idempotent: correct symlinks are skipped, installed tools are
# skipped, and anything that would be overwritten is backed up first. Daily
# workflow: update on one machine, push, then on the other machine run
#   ~/.config/install-agents.sh
# (it pulls the repo first; set AGENTS_SKIP_PULL=1 to skip, e.g. when called
# from install.sh which already pulled).
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.config}"
AGENTS_DIR="$HOME/.agents"

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# link SRC -> DEST, backing up whatever is already at DEST (unless it is
# already a symlink resolving to the same place, e.g. a relative link the
# skills CLI created).
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

# --- 0. Pull latest dotfiles (this is the "one command to sync" step) ---
if [ -z "${AGENTS_SKIP_PULL:-}" ] && [ -d "$DOTFILES/.git" ]; then
  log "Pulling latest dotfiles..."
  git -C "$DOTFILES" pull --ff-only || warn "could not fast-forward dotfiles - continuing with local state"
  git -C "$DOTFILES" submodule update --init --recursive
fi

# --- 1. Runtimes the skill tooling needs --------------------------------
# bun (for `bunx skills add ...`)
if ! have bun && [ ! -x "$HOME/.bun/bin/bun" ]; then
  log "Installing bun..."
  curl -fsSL https://bun.sh/install | bash
fi
export PATH="$HOME/.bun/bin:$PATH"

# uv + python 3.12 (for graphify)
if ! have uv; then
  log "Installing python@3.12 + uv..."
  brew install python@3.12 uv
fi

# --- 2. Instruction files: repo -> ~/.agents -> $HOME + per-agent -------
log "Linking instruction files..."
link "$DOTFILES/agents/AGENTS.md"   "$AGENTS_DIR/AGENTS.md"
link "$DOTFILES/agents/VOICE.md"    "$AGENTS_DIR/VOICE.md"
link "$DOTFILES/agents/OPINIONS.md" "$AGENTS_DIR/OPINIONS.md"

link "$AGENTS_DIR/AGENTS.md"   "$HOME/AGENTS.md"
link "$AGENTS_DIR/VOICE.md"    "$HOME/VOICE.md"
link "$AGENTS_DIR/OPINIONS.md" "$HOME/OPINIONS.md"

# per-agent global instruction files all resolve to the same AGENTS.md
link "$AGENTS_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$AGENTS_DIR/AGENTS.md" "$HOME/.gemini/GEMINI.md"

# --- 3. Repo-managed skills -> ~/.agents/skills --------------------------
log "Linking repo-managed skills into ~/.agents/skills..."
mkdir -p "$AGENTS_DIR/skills"

# code-quality lives as its own submodule in the dotfiles repo
link "$DOTFILES/code-quality-skill" "$AGENTS_DIR/skills/code-quality"

# every skill stored under agents/skills/ in the repo (run-gws, ...)
for skill in "$DOTFILES"/agents/skills/*/; do
  [ -d "$skill" ] || continue
  link "${skill%/}" "$AGENTS_DIR/skills/$(basename "$skill")"
done

# --- 4. bunx-installed skills (real dirs in ~/.agents/skills) -----------
# `skills add -g` installs into ~/.agents/skills and records ~/.agents/.skill-lock.json
if [ ! -e "$AGENTS_DIR/skills/gh-axi" ]; then
  log "Installing gh-axi skill..."
  bunx skills add kunchenguid/gh-axi --skill gh-axi -g || warn "gh-axi install failed"
fi
if [ ! -e "$AGENTS_DIR/skills/lavish" ]; then
  log "Installing lavish skill..."
  bunx skills add kunchenguid/lavish-axi --skill lavish -g || warn "lavish install failed"
fi

# --- 5. graphify ----------------------------------------------------------
# installed before the fan-out because `graphify install` drops its skill
# into ~/.claude/skills as a real dir - the adopt step below moves it into
# the hub so gemini gets it too.
if ! have graphify && [ ! -x "$HOME/.local/bin/graphify" ]; then
  log "Installing graphify..."
  uv tool install graphifyy
  export PATH="$HOME/.local/bin:$PATH"
  graphify install || warn "graphify install step failed - run 'graphify install' manually"
fi

# --- 6. Adopt stray real skill dirs into the hub -------------------------
# Anything a tool self-installed into ~/.claude/skills moves to ~/.agents/skills.
for skill in "$HOME/.claude/skills"/*/; do
  s="${skill%/}"; name="$(basename "$s")"
  [ -d "$s" ] && [ ! -L "$s" ] || continue     # only real dirs, not symlinks
  case "$name" in *.bak.*) continue ;; esac    # never adopt backups
  if [ ! -e "$AGENTS_DIR/skills/$name" ]; then
    log "adopting $name into ~/.agents/skills"
    mv "$s" "$AGENTS_DIR/skills/$name"
  fi
done

# --- 7. Fan every ~/.agents skill out to each agent ----------------------
# ~/.agents/skills is the source of truth; each agent gets per-skill symlinks.
log "Fanning skills out to claude + gemini/antigravity..."
for agent_skills in "$HOME/.claude/skills" "$HOME/.gemini/skills"; do
  mkdir -p "$agent_skills"
  for skill in "$AGENTS_DIR"/skills/*/; do
    [ -e "${skill%/}" ] || continue
    link "${skill%/}" "$agent_skills/$(basename "$skill")"
  done
done

# Note: Claude Code project memory (~/.claude/projects/<enc>/memory) is
# harness-specific, so it lives under the repo's claude/ dir and is linked by
# claude/apply.sh - not here.

log "Agent setup complete."
