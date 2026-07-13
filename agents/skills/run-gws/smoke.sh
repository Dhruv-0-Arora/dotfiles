#!/usr/bin/env bash
# Smoke test for the gws (Google Workspace CLI) install on this machine.
# Read-only probes plus --dry-run validation of every write helper.
# Never sends email, never writes to Sheets/Docs/Drive/Calendar.
#
# Usage: bash ~/.agents/skills/run-gws/smoke.sh
# Exit 0 = core surfaces healthy. Gmail/Chat are reported but do not
# fail the suite (known account limitations, see SKILL.md Gotchas).

set -u
PASS=0; FAIL=0; WARN=0

check() { # check <label> <expected-fragment> <cmd...>
  local label="$1" expect="$2"; shift 2
  local out
  out=$("$@" 2>&1)
  if grep -q "$expect" <<<"$out"; then
    echo "PASS  $label"; PASS=$((PASS+1))
  else
    echo "FAIL  $label"; echo "$out" | head -5 | sed 's/^/      /'; FAIL=$((FAIL+1))
  fi
}

probe() { # probe <label> <cmd...> — report only, never fails the suite
  local label="$1"; shift
  local out
  if out=$("$@" 2>&1) && ! grep -q '"error"' <<<"$out"; then
    echo "PASS  $label"; PASS=$((PASS+1))
  else
    echo "WARN  $label (expected on accounts without this service, see Gotchas)"
    WARN=$((WARN+1))
  fi
}

command -v gws >/dev/null || { echo "FAIL  gws not on PATH (expected ~/.cargo/bin/gws)"; exit 1; }

echo "== auth =="
check "auth status"            '"auth_method"'        gws auth status

echo "== read-only probes =="
check "calendar +agenda"       'timeMin'              gws calendar +agenda
check "workflow +standup"      'meetingCount'         gws workflow +standup-report
check "tasks tasklists list"   'tasks#taskLists'      gws tasks tasklists list
check "drive files list"       '"files"'              gws drive files list --params '{"pageSize": 1, "fields": "files(id,name)"}'
check "schema lookup"          'httpMethod'           gws schema drive.files.list

echo "== write helpers (--dry-run, nothing is sent) =="
check "gmail +send dry-run"    '"dry_run": true'      gws gmail +send --to test@example.com --subject T --body B --dry-run
check "calendar +insert dry"   '"dry_run": true'      gws calendar +insert --summary T --start 2099-01-01T10:00:00 --end 2099-01-01T11:00:00 --dry-run
check "sheets +append dry-run" '"dry_run": true'      gws sheets +append --spreadsheet FAKE_ID --values "a,b" --dry-run
check "docs +write dry-run"    '"dry_run": true'      gws docs +write --document FAKE_ID --text t --dry-run

echo "== account-dependent services (reported, not failed) =="
probe "gmail +triage"          gws gmail +triage --max 1
probe "chat spaces list"       gws chat spaces list

echo
echo "passed=$PASS failed=$FAIL warned=$WARN"
[ "$FAIL" -eq 0 ]
