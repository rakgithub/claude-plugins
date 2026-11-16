#!/bin/bash
# Stop: for each area in .claude/devflow.json with uncommitted changes, run its "check"
# command from the area's path; block finishing the turn while any fails.
# Slow suites (e.g. e2e) belong in "verify", not "check" - this runs on every turn.
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cfg="$root/.claude/devflow.json"
[ -f "$cfg" ] || exit 0
command -v jq >/dev/null || { echo "devflow: jq is required for hooks" >&2; exit 2; }
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0
cd "$root" || exit 0

areas=$(jq -r '.areas[]? | select(.check) | [.path, .check] | @tsv' "$cfg") \
  || { echo "devflow: invalid $cfg" >&2; exit 2; }

fail=""
while IFS=$'\t' read -r path check; do
  [ -n "$path" ] || continue
  git status --porcelain -- "$path" | grep -q . || continue
  out=$( (cd "$path" && bash -c "$check") 2>&1 ) \
    || fail+="--- $path checks failed ---"$'\n'"$(tail -40 <<<"$out")"$'\n'
done <<<"$areas"

if [ -n "$fail" ]; then
  echo "Checks failed - fix before finishing:" >&2
  echo "$fail" >&2
  exit 2
fi
exit 0
