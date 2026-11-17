#!/bin/bash
# Run devflow's eval suite. Extra arguments go to `claude plugin eval` (e.g. --case, --runs).
set -euo pipefail
plugin="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$plugin/evals/results/$(date +%Y-%m-%dT%H-%M-%S)"
mkdir -p "$out"
claude plugin eval "$plugin" \
  --trust-plugin --scaffold --allow-tools Bash Edit Write \
  --ablation none --no-publish \
  --output-dir "$out" --report "$out/report.html" --json "$out/result.json" \
  "$@"
