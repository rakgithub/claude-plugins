#!/bin/bash
# The fixture repo before devflow: no .claude/devflow.json, and CLAUDE.md without its
# Testing section. The repo has a test script but no lint, format or typecheck tooling.
set -euo pipefail
bash "$(dirname "${BASH_SOURCE[0]}")/../_lib/setup-fixture.sh"
rm .claude/devflow.json
sed -i.bak '/^## Testing/,$d' CLAUDE.md && rm CLAUDE.md.bak
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "Before devflow"
