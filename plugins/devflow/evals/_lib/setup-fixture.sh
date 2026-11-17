#!/bin/bash
# Shared by the cases' scaffold scripts: copy the fixture repo into the run's working
# directory and commit it on main, so devflow's baseBranch ("main") exists.
set -euo pipefail
fixture="$(cd "$(dirname "${BASH_SOURCE[0]}")/../_fixture" && pwd)"
cp -R "$fixture"/. .
git init -q -b main
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "Initial shop"
