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
  to add one (run `/devflow:init`).
- The spec folder `<specsDir>/<slug>/` from the argument. It must contain
  `prd.md`. If it doesn't, stop and suggest `/devflow:prd`.
- The root `CLAUDE.md` and the conventions file of every area the PRD is
  likely to touch, and the `openapi` file of any of them that has one.

## 1. Check the PRD is buildable

List every `[?]` open item. If any would change the design (data shape,
behaviour, scope), stop and ask the user to settle it, or to accept an
assumption you state. Do not design around a hole.

## 2. Study the code before deciding anything

Run `Explore` subagents in parallel, one per touched area, to find:
the nearest existing feature to copy, the layers a change passes through,
the existing domain modules (bounded contexts) and the domain terms the
code already uses, shared code to reuse, the tests nearest to it and their
fixtures, and anything the PRD would conflict with. Ask each for
`file:line` references, not file dumps.

Every later decision must point at something real in the repo. A choice
that cannot is a guess; say so.

New files go where the area's `## Structure` section says. If a touched
area's conventions have none, infer it from the nearest existing feature,
use that, and propose the section to the user so it gets added.

## 3. Model the domain

How the domain is modelled (layers, where rules live, how modules talk to
each other) comes from each area's `## Architecture` section. If a touched
area has none, infer it from the nearest existing feature, use that, and
propose the section to the user so it gets added. Then:

- **Language.** Map each PRD term to the name used in code. Reuse existing
  names; flag a PRD term that clashes with one, and settle it with the
  user. Use the same names in code, API, UI and tests.
- **Owning module.** Name the existing module (bounded context, feature
  folder) that owns this feature. A new module, or a feature split across
  modules, is a decision for step 4, never a default.
- **Business rules.** List every business rule from the PRD and the one
  place that enforces it, where the area's architecture says rules live.
- **Across modules.** Use the way the architecture says modules talk to
  each other; flag anything that reaches into another module's internals.

Keep it proportional: a pattern or layer the repo doesn't already use is
only ever a step 4 decision the user approves.

## 4. Decide, with the user

List the real technical decisions, the places where reasonable engineers
would choose differently (API shape, where state lives, reuse vs new,
sync vs async, error behaviour, data limits). Skip anything the conventions
already decide.

For each decision give 2–3 options, each with its trade-off in one line,
and your recommendation with the reason grounded in the code from step 2
and the domain model from step 3.
Ask the user, at most 4 decisions per round (use AskUserQuestion when
available). "You decide" → your recommendation, recorded as `[A]`.

Constraints on every option:

- Reuse existing patterns and code first; the simplest design that meets
  the acceptance criteria wins.
- A new dependency, new layer or new abstraction is only ever an explicit
  option the user approves, with why the existing code can't do it.
- No speculative configurability or future-proofing the PRD didn't ask for.

## 5. Pre-mortem

Assume it is three months later and this feature failed or caused an
incident. Write the 3–5 most likely reasons (missed state, race, contract
drift between areas, a breaking change for existing clients, a migration
on live data, performance, security, accessibility, data edge cases).
Each must be either handled in the design or listed as an accepted risk.
Check every PRD `## Constraints` item is met by the design.

## 6. Write `design.md`

In the spec folder. Mark decisions `[D]` decided or `[A]` assumption.

```
# <Feature> — Design
Status: draft
PRD: ./prd.md

## Summary            (3–5 lines: the approach in plain words)
## Areas touched      (and in which order, per devflow.json `order`)
## Domain model       (owning module; PRD term -> code name; each business
                       rule -> the one place that enforces it)
## Contracts          (every API/interface that changes: path, input,
                       output shape, errors; written out exactly. For an
                       area with `openapi`: the exact OpenAPI YAML to add
                       or change in that file)
## Flow               (how a request/interaction moves through the layers)
## Changes by area    (files to create/change, each with its full path,
                       its layer, one line of why, and the existing file
                       it is modelled on)
## States             (loading, error, empty, partial; for UI and API)
## Decisions          (each: options considered, choice, reason, [D]/[A])
## Risks              (from the pre-mortem: handled how, or accepted)
## Rollout & ops      (data migrations, run expand-then-contract on live
                       data; backward compatibility of changed contracts
                       or versioning; feature flag, if any; logs/metrics
                       that show it works in production; how to roll back)
## Traceability       (table: AC | where it is implemented | test that proves it)
```

Every acceptance criterion in the PRD appears in the traceability table.
Keep Rollout & ops proportional: for a change with no stored data, no
contract change and nothing to watch in production, write `None` with one
line of why.

If the design changes UI in an area with `"ui": true`, load the
`frontend-design` skill and record the visual direction (layout, type,
colour, key interactions) under Changes by area, so `/devflow:feature`
builds to it instead of improvising. The area's conventions and existing
design system win where they disagree.

For HTTP endpoints in an area with `openapi`, the OpenAPI YAML in
Contracts is the contract: reuse the file's existing `components`
(schemas, error responses, security) via `$ref`, follow its naming, and
cover every status code the endpoint can return, errors included. Don't
edit the `openapi` file itself here; the tasks do.

## 7. Write `tasks.md`

In the spec folder. Cut the work into tasks that each:

- deliver one observable behaviour end to end (vertical slice), never
  "all the schemas" then "all the components";
- name the PRD acceptance criteria they cover (every AC in exactly one
  task, or split explicitly across named tasks);
- leave the touched areas' `verify` commands green on their own;
- follow the dependency order between tasks; inside a task, change the
  contract first, then each area per `order`;
- when they add or change an endpoint in an area with `openapi`, list that
  file under `Files` and update it first, in the same task as the code;
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

## 8. Independent review

Run the `devflow:plan-reviewer` subagent on the spec folder. It has not
seen this conversation; that is the point. Fix every blocker and
should-fix finding in `design.md` / `tasks.md`, or tell the user why you
disagree. Re-run it once if you changed the design substantially.

## 9. Approval

Show the user: the summary, the decisions table, the task list titles, the
accepted risks, and what the reviewer found and how it was resolved. Ask
them to approve or change it. On approval set `Status: approved` in both
files.

End with: start a **new session** and run `/devflow:feature <specsDir>/<slug>`
so the build starts from the files, not this conversation. Don't start it
yourself.
