---
name: feature
description: Build a new feature or change end to end, test-first, with verify and review gates. Takes either an approved spec folder from /design (works through tasks.md one task at a time) or a plain description (writes its own short spec and plan for approval first). Use for any non-trivial feature request or issue.
argument-hint: <spec folder | issue | description>
---

# /feature

Before anything else, read `.claude/devflow.json` (areas, commands,
`order`, `rules`, `baseBranch`, `specsDir`) and the root `CLAUDE.md`. If the
config is missing, stop and tell the user to add one (run `/devflow:init`). For every area you touch, read its `conventions` file and follow
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
   design is approved. If some tasks are already ticked, this is a
   resume: `tasks.md` is the state. Run the touched areas' `verify` once
   to confirm the starting point is green, then carry on from the next
   task.
2. **Branch.** If not already on a feature branch, create
   `feature/<slug>` from `baseBranch`. If other work is in flight in this
   checkout, stop and suggest running this in a new worktree session
   instead; devflow's hooks only see the session's own project folder.
3. **Loop over tasks.** Take the first unticked task whose `Depends` are
   all ticked. For that task only:
   1. **Tests first.** If the task adds or changes an endpoint in an area
      with `openapi`, first apply the task's OpenAPI changes from
      `design.md` to that file, exactly. Then delegate to the
      `devflow:test-writer` subagent with the task, its acceptance
      criteria from the PRD and the relevant contract (for endpoints, the
      OpenAPI operation). Confirm the tests fail for the right reason.
   2. **Implement** the smallest change that makes them pass, in the files
      the task names (no new files outside them without saying why),
      following the touched area's conventions, its structure, the
      domain model (from `design.md`, or the approved plan in quick
      mode) and the config `rules`. Endpoints match their OpenAPI
      operation exactly: path, parameters, request and response schemas,
      status codes. If the task changes UI in an area with
      `"ui": true`, follow the area's conventions and existing design system.
      The red tests are the spec: make them pass by changing production
      code, never by editing them. If a test is genuinely wrong (it
      contradicts the acceptance criteria or the contract), stop and tell
      the user what is wrong and the change you propose; change it only
      once they agree. Never skip, delete or loosen a test, or copy the
      actual output into the expected value.
   3. **Verify.** Run the `verify` command of each touched area. Fix
      causes, never weaken checks. Repeat until green.
   4. **Record.** Tick the task in `tasks.md` and add one line under it:
      what was verified, plus `Test changes after red:` and each test
      changed after it failed with why (or `none`).
   5. **Pause** and show the user the task's diff summary, unless they said
      to run all tasks. Suggest committing as a checkpoint; don't commit.
      After about three tasks in one session, suggest continuing in a new
      session with the same `/devflow:feature <spec folder>`; it resumes
      from `tasks.md` with a fresh context.
4. **Drift.** If a task can't be built as designed (missing case, wrong
   contract, file doesn't exist), stop. Explain the gap and propose the
   change to `design.md` / `tasks.md` (and the `openapi` file, for a
   contract change). Never change the code's API without its spec.
   Continue only after the user agrees and the files are updated.
5. **Finish** with Review and Hand back below.

## Quick mode

1. **Spec.** Restate the request as: user story, acceptance criteria
   (testable bullets), contract changes (written out exactly: path,
   input, output, errors; for an area with `openapi`, as the exact OpenAPI
   YAML to add or change, reusing its `components`), and out-of-scope.
   State which areas are touched.
2. **Plan.** Read the conventions of each touched area, then the nearest
   existing code. Order the work per `order`. Model the change as in
   `/devflow:design` step 3, briefly: the owning module, the domain terms,
   and where each business rule lives per the area's `## Architecture`. List every file to create/change
   with its full path, its layer and the existing file it is modelled on,
   following the area's `## Structure` section (if there is none, infer it
   from the nearest existing feature and propose adding one). Then the
   test plan. **Stop and ask the user to approve the plan before writing
   code.**
3. **Branch** as in spec mode.
4. **Tests first** via `devflow:test-writer`, as in spec mode, applying
   the OpenAPI changes from the approved spec first.
5. **Implement** and **Verify** as in spec mode.
6. **Finish** with Review and Hand back.

## Review

Run the `devflow:code-reviewer` subagent on the branch diff (in spec mode,
tell it the spec folder so it also checks the diff against `design.md`).
If any area with `"ui": true` changed, also run `devflow:ui-reviewer`.

Check each finding before acting on it: reviewers can be wrong. Fix
blockers and should-fix items you agree with. For one you think is wrong,
don't change the code; keep it for the hand back with the evidence (the
code, test or spec that shows it). Then re-run the verify commands and,
if you fixed any blocker, run the same reviewer(s) once more on the new
diff. Fix what that second pass finds; don't loop a third time, list
anything left in the hand back.

## Hand back

Summarise what changed, tick off each acceptance criterion with the test
that proves it, list every test changed after it went red and why (or say
none were), list review findings you disputed or left open with why,
attach screenshots for UI changes and paste the verify
results. Draft a PR description the user can copy. Do not commit, push or
open a PR; the user does that.

Then close the loop: for each blocker the reviewers found that a written
rule would have prevented and that the area's conventions file doesn't
already state, propose that rule in one line and the section it belongs
in. Add it to the conventions file only if the user agrees. Skip this
when there were no such blockers.
