# macOS machine setup

One command provisions a brand-new Mac with all my tools and this dotfiles repo.

## Bootstrap (fresh machine)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dhruv-0-Arora/dotfiles/macos/install.sh)"
```

That installs Xcode CLT + Homebrew, clones this repo into `~/.config` (the `macos`
branch), pulls the `nvim` submodule, installs everything in the [`Brewfile`](./Brewfile),
installs Rust + `gws`, and symlinks `.zshrc` and the Claude Code config.

## Re-run on an existing machine

```bash
~/.config/install.sh
```

It is idempotent - every step checks existing state and backs up anything it
would overwrite (`*.bak.<timestamp>`).

## What gets installed

- **Bootstrap:** Xcode Command Line Tools, Homebrew, this dotfiles repo, `nvim` submodule
- **CLI (`Brewfile`):** git, gh, neovim, zellij, eza, fzf, ripgrep, fd, tree-sitter, gnupg, tailscale
- **Languages/build:** Go, cmake, llvm (C/C++), Rust via rustup
- **Apps:** Alacritty, FiraCode Nerd Font, AeroSpace, Claude Code, Spotify, gcloud SDK
- **Cargo:** `gws` (Google Workspace CLI)
- **Symlinks:** `~/.zshrc`, `~/.claude/skills`, `~/.claude/CLAUDE.md`, Claude memory,
  and `~/AGENTS.md` / `~/OPINIONS.md` / `~/VOICE.md`

## Adding a tool

Add it to the [`Brewfile`](./Brewfile) (or, for a cargo/rustup tool, to the cargo
section of [`install.sh`](./install.sh)) and re-run `install.sh`.

## Manual one-time steps

Printed at the end of `install.sh`: `gh auth login`, sign into Tailscale, launch
AeroSpace for accessibility permissions, and sign into Claude Code.
