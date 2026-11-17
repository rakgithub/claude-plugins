#!/bin/bash
# Run devflow's eval suite. Extra arguments go to `claude plugin eval` (e.g. --case, --runs).
#
# The eval sandbox can't resolve the frontend-design@claude-plugins-official dependency, and
# a plugin with an unresolved dependency doesn't load at all - every case would silently run
# without devflow. So this evaluates a temporary copy with "dependencies" removed. None of
# the cases exercise UI work, which is the only thing that dependency is used for.
set -euo pipefail
plugin="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v jq >/dev/null || { echo "run.sh needs jq" >&2; exit 1; }
copy=$(mktemp -d)
trap 'rm -rf "$copy"' EXIT

rsync -a --exclude 'evals/results' "$plugin/" "$copy/"
jq 'del(.dependencies)' "$plugin/.claude-plugin/plugin.json" >"$copy/.claude-plugin/plugin.json"

out="$plugin/evals/results/$(date +%Y-%m-%dT%H-%M-%S)"
mkdir -p "$out"
claude plugin eval "$copy" \
  --trust-plugin --scaffold --allow-tools Bash Edit Write \
  --ablation none --no-publish \
  --output-dir "$out" --report "$out/report.html" --json "$out/result.json" \
  "$@"
