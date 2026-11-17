#!/bin/bash
# Stop: run the "check" command of each area this session edited (recorded by
# format-on-edit.sh), from the area's path. While any fails, block finishing the turn so
# the agent fixes it - up to MAX_BLOCKS times in a row, then let the turn end with a
# warning shown to the user, so a stuck check never loops forever or passes silently.
# Areas whose checks pass are cleared; the next edit records them again.
# Slow suites (e.g. e2e) belong in "verify", not "check" - this runs on turns with edits.
MAX_BLOCKS=3
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cfg="$root/.claude/devflow.json"
[ -f "$cfg" ] || exit 0
command -v jq >/dev/null || { echo "devflow: jq is required for hooks" >&2; exit 2; }

sid=$(jq -r '.session_id // empty' <<<"$input")
[[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0
state="${TMPDIR:-/tmp}/devflow/$sid"
[ -s "$state.areas" ] || exit 0
cd "$root" || exit 0

fail=""
failed_paths=""
while IFS= read -r path; do
  [ -n "$path" ] || continue
  check=$(jq -r --arg p "$path" 'first(.areas[]? | select(.path == $p) | .check // empty)' "$cfg") \
    || { echo "devflow: invalid $cfg" >&2; exit 2; }
  [ -n "$check" ] || continue
  out=$( (cd "$path" && bash -c "$check") 2>&1 ) && continue
  fail+="--- $path checks failed ---"$'\n'"$(tail -40 <<<"$out")"$'\n'
  failed_paths+="$path"$'\n'
done < <(sort -u "$state.areas")

if [ -z "$fail" ]; then
  rm -f "$state.areas" "$state.blocks"
  exit 0
fi

# Keep only the failing areas, so a later turn doesn't re-run checks that passed.
printf '%s' "$failed_paths" >"$state.areas"
# Count blocks only within one turn: a stop that isn't a retry from this hook starts at 1.
blocks=1
if [ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ]; then
  blocks=$(( $(cat "$state.blocks" 2>/dev/null || echo 0) + 1 ))
fi
if [ "$blocks" -gt "$MAX_BLOCKS" ]; then
  rm -f "$state.blocks"
  msg="devflow: checks still failing after $MAX_BLOCKS fix attempts; the turn ended anyway."$'\n'"$fail"
  jq -n --arg m "$msg" '{systemMessage: $m}'
  exit 0
fi
echo "$blocks" >"$state.blocks"
echo "Checks failed - fix before finishing (attempt $blocks of $MAX_BLOCKS):" >&2
echo "$fail" >&2
exit 2
