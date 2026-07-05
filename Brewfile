# Brewfile - declarative list of everything Homebrew installs.
# Applied by `brew bundle --file=~/.config/Brewfile` (install.sh does this for you).
# Add a tool here and it becomes part of the machine setup.

# --- taps ---------------------------------------------------------------
tap "nikitabobko/tap"          # aerospace tiling window manager

# --- core CLI -----------------------------------------------------------
brew "git"                     # newer than the system git
brew "gh"                      # GitHub CLI
brew "neovim"                  # editor (config is the nvim submodule)
brew "zellij"                  # terminal multiplexer
brew "eza"                     # modern ls (aliased to `l` in .zshrc)
brew "fzf"                     # fuzzy finder
brew "ripgrep"                 # rg - used by nvim telescope / grep
brew "fd"                      # fast find - used by nvim/fzf
brew "tree-sitter"             # nvim treesitter CLI
brew "gnupg"                   # gpg (GPG_TTY is set in .zshrc)
brew "tailscale"               # mesh VPN CLI + daemon (ssh into home server)

# --- languages & build toolchain ---------------------------------------
brew "go"                      # Go toolchain
brew "cmake"                   # build system
brew "llvm"                    # clang/llvm for C/C++ compiling
# Rust is installed via rustup in install.sh (not brew) so `cargo install` works.

# --- GUI apps (casks) ---------------------------------------------------
cask "alacritty"                       # terminal
cask "font-fira-code-nerd-font"        # font Alacritty is configured to use
cask "nikitabobko/tap/aerospace"       # tiling window manager
cask "claude-code"                     # Claude Code
cask "spotify"                         # music
cask "google-cloud-sdk"                # gcloud (sourced in .zshrc)
