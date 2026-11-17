---
name: bugfix
description: Fix a bug by first reproducing it with a failing test, then the minimal root-cause fix, verify, review and hand back. Use for bug reports or regressions.
argument-hint: <issue | bug description>
---

# /bugfix

Input: an issue number/URL or a bug description (steps, expected, actual).

Before anything else, read `.claude/devflow.json` (areas, commands,
`baseBranch`) and the root `CLAUDE.md`. If the config is missing, stop and
tell the user to add one (run `/devflow:init`). Read the `conventions`
file of the area that owns the bug and follow it.

0. **Branch.** If not already on a fix branch, create `fix/<short-slug>`
   from `baseBranch` before changing anything.
1. **Reproduce.** Find the cause area by reading code and, if it is visual
   or behavioural, reproducing it in the browser (the `launchConfigs` from
   the config). For API bugs, reproduce with a request (curl or the area's
   HTTP test tool) and decide which area owns the bug. Write down the root
   cause hypothesis. If you cannot reproduce it, stop and ask the user for
   more detail.
2. **Failing test.** Delegate to the `devflow:test-writer` subagent: one
   test at the lowest level that exposes the bug (unit or API before
   end-to-end), in the area that owns the bug. Confirm it fails with the
   symptom from the report. If no automated test can reach the bug (build
   or deploy config, environment, a third-party outage), say so, write
   down the exact manual reproduction instead, and use it as the check in
   step 4. Don't invent a test that passes regardless.
3. **Fix.** Smallest change that fixes the root cause, not the symptom. No
   drive-by refactors. For a visual bug in an area with `"ui": true`, follow the
   area's conventions and existing design system. The area's `openapi` file is the contract: if the code breaks
   it, fix the code. If the spec itself is wrong, stop, show the user the
   spec change, and update the spec before the code once they agree.
   Make the failing test pass by changing production code, never by
   editing the test. If the test is wrong, stop and tell the user why and
   what you'd change; change it only once they agree. Never skip, delete
   or loosen a test, or copy the actual output into the expected value.
   Then search the codebase for the same mistake elsewhere (the same
   pattern, a copy of the function, other callers that make the same
   assumption). Don't fix those here; list them in the hand back.
4. **Verify.** The new test passes, then run the `verify` command of each
   touched area until green.
5. **Review.** Run the `devflow:code-reviewer` subagent (and
   `devflow:ui-reviewer` for visual bugs in a `"ui": true` area). Handle
   findings as in `/devflow:feature`'s Review: check each one, fix those
   you agree with, keep disputed ones with evidence, and re-review once
   if you fixed a blocker.
6. **Hand back.** Summarise the root cause, why the test proves it, how
   it was verified, any change to the test after it went red, with why,
   other places with the same mistake, and disputed or open review
   findings; draft a PR description the user can copy. Do not
   commit, push or open a PR; the user does that. Then propose
   conventions rules from review blockers as in `/devflow:feature`'s Hand
   back, and also when the bug itself came from an unwritten rule.
