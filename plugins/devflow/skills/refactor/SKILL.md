---
name: refactor
description: Restructure code without changing what it does. Pins current behaviour with tests first (characterization tests that pass on today's code), refactors in small steps that keep them green, then verifies and reviews that nothing observable changed. Use for refactors, cleanups, renames, extractions and moving code. Not for changing behaviour (that is /feature) or fixing bugs (that is /bugfix).
argument-hint: <what to restructure and why>
---

# /refactor — same behaviour, better code

Before anything else, read `.claude/devflow.json` (areas, commands,
`baseBranch`) and the root `CLAUDE.md`. If the config is missing, stop and
tell the user to add one (run `/devflow:init`). Read the `conventions`
file of every area in scope and follow it.

A refactor changes no observable behaviour: same outputs, errors, API
responses, UI and side effects. If you find a bug on the way, don't fix
it here; note it and suggest `/devflow:bugfix` afterwards.

0. **Branch.** If not already on a refactor branch, create
   `refactor/<short-slug>` from `baseBranch`.
1. **Scope.** State the goal (what gets better, and why it matters), the
   files and public interfaces in scope, and what stays out. If the
   refactor changes a public interface (an exported API, an endpoint, a
   module boundary other code uses), list every caller. When the scope is
   more than a handful of files or touches a public interface, **stop and
   ask the user to approve it.**
2. **Pin the behaviour.** Find the tests that already cover the code in
   scope and run them; they must pass now. For behaviour in scope that no
   test covers, delegate to the `devflow:test-writer` subagent in
   characterization mode: tests that assert what the code does today and
   pass against it. Do this before changing any production code.
3. **Plan the steps.** Cut the refactor into small steps (rename, extract,
   move, inline, change a signature and its callers), each of which leaves
   every test green. Order them so the riskiest step is easiest to undo.
4. **Refactor, one step at a time.** After each step, run the affected
   test files with `testOne`, then the area's `check`. If something goes
   red, the step changed behaviour: undo or fix the step, never the test.
   Tests may change only where the refactor moved or renamed what they
   import or call; record each such change.
5. **Verify.** Run the `verify` command of each touched area until green.
   The pinned tests must be unchanged apart from the recorded moves and
   renames.
6. **Review.** Run the `devflow:code-reviewer` subagent and tell it this
   is a refactor, so any behaviour change is a blocker. Handle findings as
   in `/devflow:feature`'s Review.
7. **Hand back.** Summarise what changed structurally and why it is
   better, the tests that pin the behaviour (existing and new), every
   test change with why, bugs you found and left alone, and how it was
   verified. Draft a PR description the user can copy. Do not commit,
   push or open a PR; the user does that.
