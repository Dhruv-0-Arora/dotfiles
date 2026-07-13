# Claude Code config

Portable Claude Code settings tracked in the dotfiles repo:

- `settings.json` - model, theme, statusline, enabled plugins
- `statusline-command.sh` - the custom forest-green statusline
- `themes/bamboo.json` - the `custom:bamboo` theme

These are **copied**, not symlinked, into `~/.claude/`. Claude Code rewrites
`settings.json` in place (changing theme/model via `/config`, toggling plugins),
and tools that save atomically would clobber a symlink with a real file - so a
copy-based flow is the robust choice.

One item here is **symlinked**, not copied:

- `memory/` - Claude Code's persistent project memory for the `~/.config` repo.
  It is symlinked into `~/.claude/projects/<enc>/memory` (by `apply.sh`) so that
  memory writes land directly in the repo. It lives here, not in `agents/`,
  because it is a Claude-Code-specific feature (Gemini does not use it).

Not tracked: `settings.local.json` (machine-local permissions) and all runtime
state (sessions, history, cache, ...).

## Sync

```bash
# repo -> ~/.claude   (new machine, or after `git pull`)
~/.config/claude/apply.sh

# ~/.claude -> repo   (after tweaking settings; then commit + push)
~/.config/claude/update.sh
```

Both are idempotent - identical files are skipped, and `apply.sh` backs up
anything it would overwrite (`*.bak.<timestamp>`). `install.sh` runs `apply.sh`
automatically on a fresh machine.

To track another file, add its path to the `FILES` array in **both** scripts.
