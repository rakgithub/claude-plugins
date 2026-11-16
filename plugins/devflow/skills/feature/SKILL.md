---
name: feature
description: Build a new feature or change end to end, test-first, with verify and review gates. Takes either an approved spec folder from /design (works through tasks.md one task at a time) or a plain description (writes its own short spec and plan for approval first). Use for any non-trivial feature request or issue.
argument-hint: <spec folder | issue | description>
---

# /feature

Before anything else, read `.claude/devflow.json` (areas, commands,
`order`, `rules`, `baseBranch`, `specsDir`) and the root `CLAUDE.md`. If the
config is missing, stop and tell the user to add one (see the devflow
README). For every area you touch, read its `conventions` file and follow
it; those rules override anything generic here.

Pick the mode from the input:

- **Spec mode:** the input is a spec folder (or a slug under `specsDir`)
  whose `design.md` and `tasks.md` say `Status: approved`. If they exist but
  are not approved, stop and point the user to `/devflow:design`.
- **Quick mode:** anything else. For a vague or multi-part requirement,
  suggest `/devflow:prd` then `/devflow:design` first, and continue in quick
  mode only if the user wants to.

## Spec mode

1. **Load.** Read `prd.md`, `design.md` and `tasks.md`. Don't re-plan; the
   design is approved.
2. **Branch.** If not already on a feature branch, create
   `feature/<slug>` from `baseBranch` (use a worktree if other work is in
   flight).
3. **Loop over tasks.** Take the first unticked task whose `Depends` are
   all ticked. For that task only:
   1. **Tests first.** Delegate to the `devflow:test-writer` subagent with
      the task, its acceptance criteria from the PRD and the relevant
      contract from `design.md`. Confirm the tests fail for the right
      reason.
   2. **Implement** the smallest change that makes them pass, in the files
      the task names, following the touched area's conventions and the
      config `rules`.
   3. **Verify.** Run the `verify` command of each touched area. Fix
      causes, never weaken checks. Repeat until green.
   4. **Record.** Tick the task in `tasks.md` and add one line under it:
      what was verified.
   5. **Pause** and show the user the task's diff summary, unless they said
      to run all tasks. Suggest committing as a checkpoint; don't commit.
4. **Drift.** If a task can't be built as designed (missing case, wrong
   contract, file doesn't exist), stop. Explain the gap and propose the
   change to `design.md` / `tasks.md`. Continue only after the user agrees
   and the files are updated.
5. **Finish** with Review and Hand back below.

## Quick mode

1. **Spec.** Restate the request as: user story, acceptance criteria
   (testable bullets), contract changes (written out exactly: path,
   input, output, errors), and out-of-scope. State which areas are touched.
2. **Plan.** Read the conventions of each touched area, then the nearest
   existing code. Order the work per `order`. List files to create/change
   and the test plan. **Stop and ask the user to approve the plan before
   writing code.**
3. **Branch** as in spec mode.
4. **Tests first** via `devflow:test-writer`, as in spec mode.
5. **Implement** and **Verify** as in spec mode.
6. **Finish** with Review and Hand back.

## Review

Run the `devflow:code-reviewer` subagent on the branch diff (in spec mode,
tell it the spec folder so it also checks the diff against `design.md`).
If any area with `"ui": true` changed, also run `devflow:ui-reviewer`.
Fix blockers and should-fix items, then re-run the verify commands.

## Hand back

Summarise what changed, tick off each acceptance criterion with the test
that proves it, attach screenshots for UI changes and paste the verify
results. Draft a PR description the user can copy. Do not commit, push or
open a PR; the user does that.
