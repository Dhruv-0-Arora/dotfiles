---
name: run-gws
description: Run, smoke-test, and drive the gws Google Workspace CLI - send email, read/append sheets, calendar agenda/insert, drive upload, docs write, tasks, and workflow helpers like standup-report. Use when asked to run gws, check Google Workspace from the terminal, or automate Gmail/Sheets/Calendar/Drive.
---

# Run gws (Google Workspace CLI)

`gws` is a Rust CLI installed at `~/.cargo/bin/gws` (already on PATH).
It exposes raw Google API methods (`gws <service> <resource> <method> --params '<JSON>'`) plus curated `+helper` commands.
It is already authenticated on this machine via OAuth2 (`~/.config/gws/client_secret.json`, tokens in the macOS keyring).
There is nothing to build or install.

## Smoke test (agent path - run this first)

```bash
bash ~/.agents/skills/run-gws/smoke.sh
```

Read-only probes plus `--dry-run` validation of every write helper.
Sends nothing, writes nothing.
Expect `passed=10 failed=0 warned=2` - the 2 warnings (Gmail, Chat) are account limitations, see Gotchas.

## Helper commands (all verified on this machine)

Read-only:

```bash
gws calendar +agenda                          # upcoming events (today window)
gws workflow +standup-report                  # today's meetings + open tasks
gws workflow +weekly-digest                   # week's meetings + unread count
gws gmail +triage --max 5                     # unread summary (FAILS here, see Gotchas)
gws sheets +read --spreadsheet <ID> --range "A1:C3"
gws tasks tasklists list
gws drive files list --params '{"pageSize": 3, "fields": "files(id,name,mimeType)"}'
```

Write helpers - **always validate with `--dry-run` first**, then drop the flag to execute:

```bash
gws gmail +send --to a@b.com --subject "Hi" --body "..." --dry-run
gws calendar +insert --summary "X" --start 2026-07-06T10:00:00 --end 2026-07-06T11:00:00 --dry-run
gws sheets +append --spreadsheet <ID> --values "Alice,95" --dry-run
gws docs +write --document <ID> --text "..." --dry-run
gws drive +upload ./file.txt --name "My File" --dry-run
```

`--dry-run` prints the exact HTTP method, URL, and body without calling the API.
Confirm with the user before running any outward-facing write (email, chat) without `--dry-run`.

## API schema discovery

Any raw method's parameters can be inspected before calling it:

```bash
gws schema sheets.spreadsheets.values.append
gws schema drive.files.list
```

## Output formats

Raw API commands (`gws drive files list ...`) default to JSON.
`+helper` commands default to **table** - pass `--format json` explicitly when parsing their output.
`--format table|yaml|csv|json` works on both.
The line `Using keyring backend: keyring` goes to stderr on every call - ignore it, or `2>/dev/null` when parsing.

## Other surfaces (exist, not verified here)

`gws gmail +watch` and `gws events +subscribe` stream NDJSON and block; run in background if needed.
`modelarmor` helpers require a GCP Model Armor template and cloud-platform scope.
`script +push` requires an Apps Script project.
None of these were exercised on this machine - treat their docs as hypotheses.

## Gotchas

- **Gmail returns `FAILED_PRECONDITION` (400) on this machine.**
  The signed-in Google account is not Gmail-backed (it is an outlook.com-based Google account), so every `gmail` call fails with `Precondition check failed`.
  This is an account limitation, not a CLI or auth bug - do not try to fix it by re-authenticating.
- **Chat returns 403 `insufficient authentication scopes`.**
  The current token was not granted Chat scopes.
  Fix requires an interactive re-login: suggest the user run `! gws auth login -s chat` (opens a browser, cannot be done headlessly).
- `workflow +weekly-digest` degrades gracefully: it prints a Gmail warning to stderr and reports `unreadEmails: 0` instead of failing.
- `calendar +agenda` returning `count 0` with a valid `timeMin/timeMax` window means auth is fine and the calendar is genuinely empty - not an error.

## Troubleshooting

- `error[api]: Precondition check failed.` on gmail commands: account has no Gmail mailbox (see Gotchas). Expected.
- `error[api]: Request had insufficient authentication scopes.`: token lacks that service's scope; re-login with `gws auth login -s <service>` (interactive, browser).
- Auth state unclear: `gws auth status` prints JSON with `client_config_exists` and the enabled API list.
