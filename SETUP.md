# macOS machine setup

One command provisions a brand-new Mac with all my tools and this dotfiles repo.

## Bootstrap (fresh machine)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dhruv-0-Arora/dotfiles/macos/install.sh)"
```

That installs Xcode CLT + Homebrew, clones this repo into `~/.config` (the `macos`
branch), pulls the `nvim` submodule, installs everything in the [`Brewfile`](./Brewfile),
installs Rust + `gws`, symlinks `.zshrc`, applies the Claude Code config
([`claude/`](./claude/)), and sets up the agent hub.

## Re-run on an existing machine

```bash
~/.config/install.sh
```

It is idempotent - every step checks existing state and backs up anything it
would overwrite (`*.bak.<timestamp>`).

## What gets installed

- **Bootstrap:** Xcode Command Line Tools, Homebrew, this dotfiles repo, `nvim` + `code-quality-skill` submodules
- **CLI (`Brewfile`):** git, gh, neovim, zellij, eza, fzf, ripgrep, fd, tree-sitter, gnupg, tailscale
- **Languages/build:** Go, cmake, llvm (C/C++), python@3.12 + uv, Rust via rustup
- **Apps:** Alacritty, FiraCode Nerd Font, AeroSpace, Claude Code, Spotify, gcloud SDK
- **Cargo:** `gws` (Google Workspace CLI)
- **Symlinks:** `~/.zshrc`, plus everything `install-agents.sh` manages (below)

## Agent setup (`install-agents.sh`)

`install.sh` calls this, but it also runs standalone - it is the one command to
sync agent config across machines (update here, push, run there):

```bash
~/.config/install-agents.sh
```

It pulls the repo, then maintains the `~/.agents` hub:

- `~/.agents/AGENTS.md|VOICE.md|OPINIONS.md` -> `~/.config/agents/` (repo)
- `~/AGENTS.md|VOICE.md|OPINIONS.md` -> `~/.agents/`
- `~/.claude/CLAUDE.md` and `~/.gemini/GEMINI.md` -> `~/.agents/AGENTS.md`
- `~/.agents/skills/` is the single skills store:
  - `code-quality` -> the `code-quality-skill` submodule
  - repo skills (`run-gws`, ...) -> `~/.config/agents/skills/`
  - `gh-axi` + `lavish` installed via `bunx skills add ... -g` (skipped if present)
  - `graphify` installed via `uv tool install graphifyy` + `graphify install`
  - any skill a tool self-installs into `~/.claude/skills` gets adopted into the hub
- every hub skill is fanned out as a symlink into `~/.claude/skills/` and `~/.gemini/skills/`

Installs bun if missing (needed for `bunx skills`).

### Capturing the live hub back into the repo

`install-agents.sh` flows repo -> `~/.agents`. The reverse - snapshotting skills
that were installed live (`bunx`/`uv`: `gh-axi`, `lavish`, `chrome-devtools-axi`,
`graphify`) into the repo so they are version-controlled - is:

```bash
~/.config/agents/update.sh
```

It copies each real `~/.agents/skills/*` dir (and any real `*.md`) into the repo,
skipping symlinks already tracked and an editable `IGNORE` list (`astute`,
`gcal-axi` - not from public sources, and this repo is public). Review + commit
after running.

## Claude Code config (`claude/`)

Harness-**dependent** Claude Code config lives in [`claude/`](./claude/), kept
separate from the harness-independent `agents/` hub above:

- `settings.json`, `statusline-command.sh`, `themes/` are **copied** into
  `~/.claude/` (not symlinked - Claude Code rewrites these in place)
- `memory/` is **symlinked** into `~/.claude/projects/<enc>/memory` (Claude Code
  writes to it continuously, so we want those writes to land in the repo)

`install.sh` applies them; to sync by hand:

```bash
~/.config/claude/apply.sh    # repo -> ~/.claude  (new machine / after a pull)
~/.config/claude/update.sh   # ~/.claude -> repo  (after tweaking, before commit)
```

See [`claude/README.md`](./claude/README.md) for details.

## Adding a tool

Add it to the [`Brewfile`](./Brewfile) (or, for a cargo/rustup tool, to the cargo
section of [`install.sh`](./install.sh)) and re-run `install.sh`.

For a new skill: put it in `agents/skills/` in this repo (or `bunx skills add ... -g`,
then run `~/.config/agents/update.sh` to capture it into the repo), then re-run
`install-agents.sh`.

## Manual one-time steps

Printed at the end of `install.sh`: `gh auth login`, sign into Tailscale, launch
AeroSpace for accessibility permissions, and sign into Claude Code.
