#!/bin/bash
# Tests for format-on-edit.sh and stop-gate.sh against a throwaway repo.
# Run: bash hooks/test-hooks.sh   (needs jq and git)
set -u
hooks="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
repo="$work/repo"
mkdir -p "$repo/.claude" "$repo/web" "$repo/api" "$work/tmp"
cat >"$repo/.claude/devflow.json" <<'EOF'
{ "areas": [
  { "name": "web", "path": "web", "check": "test ! -f FAIL",
    "onEdit": [{ "match": "\\.ts$", "run": "test ! -f LINTFAIL || { echo lint-error; exit 1; }" }] },
  { "name": "api", "path": "api", "check": "echo ran >> ../api.log" } ] }
EOF
export CLAUDE_PROJECT_DIR="$repo" TMPDIR="$work/tmp"
state="$work/tmp/devflow/s1"
failures=0

edit() { echo "{\"session_id\":\"${2:-s1}\",\"tool_input\":{\"file_path\":\"$repo/$1\"}}" | bash "$hooks/format-on-edit.sh" 2>"$work/err"; }
stop() { echo "{\"session_id\":\"s1\",\"stop_hook_active\":$1}" | bash "$hooks/stop-gate.sh" >"$work/out" 2>"$work/err"; }
expect() { # expect <description> <actual> <expected>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (got $2, want $3)"; failures=$((failures + 1)); fi
}

echo x >"$repo/api/user.ts"
stop false; expect "no session edits: turn ends" $? 0
expect "no session edits: other areas' checks don't run" "$([ -f "$repo/api.log" ] && echo ran || echo skipped)" skipped

echo x >"$repo/web/a.ts"
edit web/a.ts; expect "edit with passing onEdit" $? 0
expect "edit records its area" "$(cat "$state.areas")" web
stop false; expect "passing check: turn ends" $? 0
expect "passing check clears state" "$([ -f "$state.areas" ] && echo kept || echo cleared)" cleared

touch "$repo/web/FAIL"; edit web/a.ts
stop false; expect "failing check blocks (1)" $? 2
stop true;  expect "failing check blocks (2)" $? 2
stop true;  expect "failing check blocks (3)" $? 2
stop true;  expect "after 3 blocks the turn ends" $? 0
expect "and the user is warned" "$(jq -r '.systemMessage | test("still failing")' "$work/out")" true
stop false; expect "next turn blocks again" $? 2
rm "$repo/web/FAIL"
stop true;  expect "fixed check: turn ends" $? 0

touch "$repo/web/LINTFAIL"
edit web/a.ts; expect "failing onEdit is reported" $? 2
expect "onEdit output goes to the agent" "$(grep -qx lint-error "$work/err" && echo yes)" yes
rm "$repo/web/LINTFAIL"

edit web/a.ts "../escape"; expect "unsafe session id is ignored" $? 0
expect "no state written for it" "$(ls "$work/tmp" | grep -c escape)" 0

CLAUDE_PROJECT_DIR="$work/tmp" bash "$hooks/stop-gate.sh" <<<'{"session_id":"s1"}'
expect "no devflow.json: no-op" $? 0

[ "$failures" -eq 0 ] && echo "all hook tests passed" || { echo "$failures failed"; exit 1; }
