#!/bin/bash
# PostToolUse (Edit|Write): run the "onEdit" steps of the area that owns the edited file,
# as configured in the project's .claude/devflow.json. Each step runs from the area's path
# with the file in $FILE. Failures are reported back to the agent (exit 2).
# It also records the area as edited by this session, so the Stop gate checks only areas
# this session changed (not the user's own uncommitted work).
# No config, a file outside the project, or a file in no area -> nothing to do.
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cfg="$root/.claude/devflow.json"
[ -f "$cfg" ] || exit 0
command -v jq >/dev/null || { echo "devflow: jq is required for hooks" >&2; exit 2; }

f=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$f" ] && [ -f "$f" ] || exit 0
rel="${f#"$root"/}"
[ "$rel" != "$f" ] || exit 0

# Most specific area wins (longest path prefix); "." is the whole repo.
area=$(jq -c --arg rel "$rel" '
  [.areas[]? | select(.path == "." or ((.path + "/") as $p | $rel | startswith($p)))]
  | max_by(.path | length) // empty' "$cfg") || { echo "devflow: invalid $cfg" >&2; exit 2; }
[ -n "$area" ] || exit 0
path=$(jq -r '.path' <<<"$area")
dir="$root/$path"

# The session id names the state file; only accept a plain id so it can't escape the dir.
sid=$(jq -r '.session_id // empty' <<<"$input")
if [[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]]; then
  state="${TMPDIR:-/tmp}/devflow/$sid"
  mkdir -p "${state%/*}" && echo "$path" >>"$state.areas"
fi

fail=""
while IFS= read -r step; do
  match=$(jq -r '.match // "."' <<<"$step")
  run=$(jq -r '.run' <<<"$step")
  [[ "$f" =~ $match ]] || continue
  out=$(cd "$dir" && FILE="$f" bash -c "$run" 2>&1) || fail+="$ $run"$'\n'"$out"$'\n'
done < <(jq -c '.onEdit[]?' <<<"$area")

if [ -n "$fail" ]; then
  echo "$fail" >&2
  exit 2
fi
exit 0
