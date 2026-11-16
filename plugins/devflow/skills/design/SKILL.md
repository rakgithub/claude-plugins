---
name: design
description: Acts as a tech lead to turn an approved PRD into a technical design grounded in the existing codebase, with explicit trade-off decisions made by the user, an independent plan review, and a task list of small test-first slices. Use after /prd, when the user runs /design, or asks how to build a clarified requirement. Not for clarifying the requirement itself (that is /prd) or for writing code (that is /feature).
argument-hint: <slug or path to the spec folder>
---

# /design — from PRD to an approved plan

Act as the tech lead for this repo. Your job is to decide **how** to build
what the PRD says, in the way this codebase already works, and to cut it
into tasks `/devflow:feature` can build one at a time. Write no production
code and no tests.

## 0. Load the inputs

- `.claude/devflow.json`: `specsDir`, the `areas` (path, conventions file,
  commands), `order` and `rules`. If it is missing, stop and tell the user
  to add one (see the devflow README).
- The spec folder `<specsDir>/<slug>/` from the argument. It must contain
  `prd.md`. If it doesn't, stop and suggest `/devflow:prd`.
- The root `CLAUDE.md` and the conventions file of every area the PRD is
  likely to touch.

## 1. Check the PRD is buildable

List every `[?]` open item. If any would change the design (data shape,
behaviour, scope), stop and ask the user to settle it, or to accept an
assumption you state. Do not design around a hole.

## 2. Study the code before deciding anything

Run `Explore` subagents in parallel, one per touched area, to find:
the nearest existing feature to copy, the layers a change passes through,
shared code to reuse, the tests nearest to it and their fixtures, and
anything the PRD would conflict with. Ask each for `file:line` references,
not file dumps.

Every later decision must point at something real in the repo. A choice
that cannot is a guess; say so.

## 3. Decide, with the user

List the real technical decisions, the places where reasonable engineers
would choose differently (API shape, where state lives, reuse vs new,
sync vs async, error behaviour, data limits). Skip anything the conventions
already decide.

For each decision give 2–3 options, each with its trade-off in one line,
and your recommendation with the reason grounded in the code from step 2.
Ask the user, at most 4 decisions per round (use AskUserQuestion when
available). "You decide" → your recommendation, recorded as `[A]`.

Constraints on every option:

- Reuse existing patterns and code first; the simplest design that meets
  the acceptance criteria wins.
- A new dependency, new layer or new abstraction is only ever an explicit
  option the user approves, with why the existing code can't do it.
- No speculative configurability or future-proofing the PRD didn't ask for.

## 4. Pre-mortem

Assume it is three months later and this feature failed or caused an
incident. Write the 3–5 most likely reasons (missed state, race, contract
drift between areas, performance, accessibility, data edge cases). Each
must be either handled in the design or listed as an accepted risk.

## 5. Write `design.md`

In the spec folder. Mark decisions `[D]` decided or `[A]` assumption.

```
# <Feature> — Design
Status: draft
PRD: ./prd.md

## Summary            (3–5 lines: the approach in plain words)
## Areas touched      (and in which order, per devflow.json `order`)
## Contracts          (every API/interface that changes: path, input,
                       output shape, errors; written out exactly)
## Flow               (how a request/interaction moves through the layers)
## Changes by area    (files to create/change, each with one line of why;
                       the existing file it is modelled on)
## States             (loading, error, empty, partial; for UI and API)
## Decisions          (each: options considered, choice, reason, [D]/[A])
## Risks              (from the pre-mortem: handled how, or accepted)
## Traceability       (table: AC | where it is implemented | test that proves it)
```

Every acceptance criterion in the PRD appears in the traceability table.

## 6. Write `tasks.md`

In the spec folder. Cut the work into tasks that each:

- deliver one observable behaviour end to end (vertical slice), never
  "all the schemas" then "all the components";
- name the PRD acceptance criteria they cover (every AC in exactly one
  task, or split explicitly across named tasks);
- leave the touched areas' `verify` commands green on their own;
- follow the dependency order, contracts first, then areas per `order`;
- are small: about 1–5 production files plus their tests. Split anything
  bigger.

```
# <Feature> — Tasks
Status: draft

- [ ] T1 <behaviour, in user/API terms>
  AC: AC1
  Area: <area name(s)>
  Depends: —
  Files: <paths>
  Tests: <test files and what they assert>
  Done: <verify command(s) green> + <observable check>
```

## 7. Independent review

Run the `devflow:plan-reviewer` subagent on the spec folder. It has not
seen this conversation; that is the point. Fix every blocker and
should-fix finding in `design.md` / `tasks.md`, or tell the user why you
disagree. Re-run it once if you changed the design substantially.

## 8. Approval

Show the user: the summary, the decisions table, the task list titles, the
accepted risks, and what the reviewer found and how it was resolved. Ask
them to approve or change it. On approval set `Status: approved` in both
files.

End with: start a **new session** and run `/devflow:feature <specsDir>/<slug>`
so the build starts from the files, not this conversation. Don't start it
yourself.
