---
name: agents-hub-structure
description: "Dhruv's ~/.agents hub - single source for skills and instruction files, fanned out to claude/gemini via symlinks, synced through dotfiles"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0fd764cd-d1ca-460a-be70-6a2696a94328
---

Dhruv syncs all agentic config across machines through `~/.config` (dotfiles repo, `macos` branch) via `~/.config/install-agents.sh` (idempotent, run after pulling on any machine).

The dotfiles repo separates harness-**independent** config (`~/.config/agents/`) from harness-**dependent** config (`~/.config/claude/`).

Structure (as of 2026-07-13):
- `~/.agents/` is the hub; `~/.agents/skills/` is the ONLY canonical skills store.
- Harness-independent, repo-backed: `~/.config/agents/{AGENTS.md,VOICE.md,OPINIONS.md,skills/}` and the `code-quality-skill` submodule. AGENTS.md/skills must stay harness-neutral - reference `~/.agents/...`, never `~/.claude/...`.
- Harness-dependent (Claude Code only), repo-backed under `~/.config/claude/`: `settings.json`, `statusline-command.sh`, `themes/` (copied into `~/.claude/` by `claude/apply.sh`), and `memory/` (symlinked into `~/.claude/projects/<enc>/memory`).
- `~/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md` all resolve (via `~/.agents/AGENTS.md`) to the repo file - editing any of them edits the repo copy.
- Per-agent skills (`~/.claude/skills/*`, `~/.gemini/skills/*`) are symlinks into `~/.agents/skills/`; never create a real skill dir there - put new skills in `~/.config/agents/skills/` (repo) or install with `bunx skills add ... -g`, then run `~/.config/agents/update.sh` to capture live skills into the repo, then re-run `install-agents.sh` (it also adopts stray real dirs into the hub).
- Claude project memory for `~/.config` is a symlink into the repo (`~/.config/claude/memory`), so memories sync between machines.

**Why:** one command updates every agent (claude, gemini/antigravity, future ones) on a new or existing machine with zero manual config.
**How to apply:** when adding/changing skills or agent instruction files, change the repo side and re-run `install-agents.sh`; never hand-edit the symlinked destinations' structure.
