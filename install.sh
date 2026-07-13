#!/usr/bin/env bash
#
# install.sh - provision a fresh macOS machine with Dhruv's tools + dotfiles.
#
# Safe to run more than once: every step checks for existing state before
# acting, and anything it would overwrite is backed up first.
#
# Fresh machine (nothing cloned yet), run the one-liner:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dhruv-0-Arora/dotfiles/macos/install.sh)"
#
# Already have the repo:
#   ~/.config/install.sh
#
set -euo pipefail

# --- config -------------------------------------------------------------
DOTFILES="${DOTFILES:-$HOME/.config}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Dhruv-0-Arora/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-macos}"   # macOS configs live on the macos branch
GWS_REPO="https://github.com/googleworkspace/cli"   # gws (google-workspace-cli)

# --- helpers ------------------------------------------------------------
log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# link SRC -> DEST, backing up whatever is already at DEST (unless it is
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

# --- 1. Xcode Command Line Tools (gives us git) ------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (accept the GUI prompt)..."
  xcode-select --install || true
  # wait for the user to finish the GUI installer
  until xcode-select -p >/dev/null 2>&1; do sleep 15; done
fi

# --- 2. Homebrew --------------------------------------------------------
if ! have brew; then
  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# put brew on PATH for the rest of this script (Apple Silicon path)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- 3. Dotfiles repo (clone into ~/.config) ---------------------------
# install.sh may be running from a curl pipe (no repo yet) or from inside an
# existing clone. Either way, make sure ~/.config is our repo on the right branch.
if [ -d "$DOTFILES/.git" ]; then
  log "Dotfiles already present at $DOTFILES - updating..."
  git -C "$DOTFILES" fetch origin
  git -C "$DOTFILES" checkout "$DOTFILES_BRANCH"
  git -C "$DOTFILES" pull --ff-only origin "$DOTFILES_BRANCH" || warn "could not fast-forward"
else
  if [ -e "$DOTFILES" ] && [ -n "$(ls -A "$DOTFILES" 2>/dev/null)" ]; then
    # ~/.config exists with stray files (common on a fresh mac): move it aside.
    bak="${DOTFILES}.bak.$(date +%Y%m%d%H%M%S)"
    warn "moving existing $DOTFILES -> $bak"
    mv "$DOTFILES" "$bak"
  fi
  log "Cloning dotfiles ($DOTFILES_BRANCH branch) into $DOTFILES..."
  git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES"
fi

# nvim is a submodule of the dotfiles repo
log "Fetching submodules (nvim)..."
git -C "$DOTFILES" submodule update --init --recursive

# --- 4. Homebrew bundle (all the CLI tools + apps + font) --------------
log "Installing everything in the Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

# fzf key-bindings / completion
if [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# --- 5. Rust (rustup) + cargo tools ------------------------------------
if ! have rustc; then
  log "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
# shellcheck disable=SC1090
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# gws - Google Workspace CLI (installed from git, lands in ~/.cargo/bin/gws)
if ! have gws; then
  log "Installing gws (google-workspace-cli) via cargo..."
  cargo install --git "$GWS_REPO" || warn "gws install failed - run 'cargo install --git $GWS_REPO' manually"
fi

# --- 6. Symlinks -------------------------------------------------------
# .zshrc lives in the repo; $HOME/.zshrc points at it.
link "$DOTFILES/.zshrc" "$HOME/.zshrc"

# --- 7. Agentic setup (~/.agents hub, skills, instruction files) --------
# Separate script so it can be re-run on its own to sync agent config:
#   ~/.config/install-agents.sh
log "Running agent setup..."
AGENTS_SKIP_PULL=1 "$DOTFILES/install-agents.sh"

# --- 7b. Claude Code config (theme, statusline, settings) --------------
# Copied (not symlinked) because Claude Code rewrites settings.json in place.
# Re-sync back to the repo later with ~/.config/claude/update.sh.
log "Applying Claude Code config..."
"$DOTFILES/claude/apply.sh"

# --- 8. Done -----------------------------------------------------------
log "Setup complete."
cat <<'EOF'

Next steps (manual, one-time):
  - gh auth login                 # authenticate GitHub, then optionally switch
                                  # the dotfiles remote to SSH:
                                  #   git -C ~/.config remote set-url origin \
                                  #     git@github.com:Dhruv-0-Arora/dotfiles.git
  - sudo tailscaled install-system-daemon   # start the tailscale daemon, then:
    sudo tailscale up                        # sign in (needed for ssh to home server)
  - Launch AeroSpace once so it registers for accessibility permissions.
  - claude                        # sign in to Claude Code.
  - Restart your terminal (or `exec zsh`) to pick up the new shell config.

  Note: `dirtint` (used by the `l` function in ~/Documents) is a personal
  Rust crate at ~/Documents/dirtint - clone/build it separately if you want it.
EOF
