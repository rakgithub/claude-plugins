---
name: bugfix
description: Fix a bug by first reproducing it with a failing test, then the minimal root-cause fix, verify, review and hand back. Use for bug reports or regressions.
argument-hint: <issue | bug description>
---

# /bugfix

Input: an issue number/URL or a bug description (steps, expected, actual).

Before anything else, read `.claude/devflow.json` (areas, commands,
`baseBranch`) and the root `CLAUDE.md`. If the config is missing, stop and
tell the user to add one (see the devflow README). Read the `conventions`
file of the area that owns the bug and follow it.

1. **Reproduce.** Find the cause area by reading code and, if it is visual
   or behavioural, reproducing it in the browser (the `launchConfigs` from
   the config). For API bugs, reproduce with a request (curl or the area's
   HTTP test tool) and decide which area owns the bug. Write down the root
   cause hypothesis. If you cannot reproduce it, stop and ask the user for
   more detail.
2. **Failing test.** Delegate to the `devflow:test-writer` subagent: one
   test at the lowest level that exposes the bug (unit or API before
   end-to-end), in the area that owns the bug. Confirm it fails with the
   symptom from the report.
3. **Fix.** Smallest change that fixes the root cause, not the symptom. No
   drive-by refactors.
4. **Verify.** The new test passes, then run the `verify` command of each
   touched area until green.
5. **Review.** Run the `devflow:code-reviewer` subagent (and
   `devflow:ui-reviewer` for visual bugs in a `"ui": true` area). Fix
   findings.
6. **Hand back.** Work on a local branch `fix/<short-slug>` from
   `baseBranch`. Summarise the root cause, why the test proves it, and how
   it was verified; draft a PR description the user can copy. Do not
   commit, push or open a PR; the user does that.
