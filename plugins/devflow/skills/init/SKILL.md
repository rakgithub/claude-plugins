---
name: init
description: Sets devflow up in a repo. Reads the codebase to propose .claude/devflow.json (areas and their check, verify, test and format commands) and the conventions sections devflow relies on (Structure, Architecture, API, Testing), and writes them once the user approves. Use when the user runs /init for devflow, or another devflow skill stops because .claude/devflow.json is missing.
argument-hint: (no arguments)
---

# /init — set devflow up in this repo

You propose; the user approves; then you write. Never invent a command the
repo doesn't already have, and add no dependencies.

## 1. Look before proposing

If `.claude/devflow.json` already exists, read it and treat this as an
update: propose changes to it, never a rewrite.

Read the root manifests and workspace files (for example `package.json`
and its lockfile, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`,
`go.mod`, `pyproject.toml`, `Cargo.toml`), the root `CLAUDE.md`, any CI
workflow (it shows what the team actually runs), and `.claude/launch.json`.
In a large repo, run `Explore` subagents in parallel, one per candidate
area.

## 2. Propose the areas

An area is a part of the repo with its own commands: each app or package
in a monorepo, or one area with `path: "."`. For each, find from its
existing scripts:

- `check`: the fast checks (lint, format check, typecheck, unit tests).
  It runs whenever a turn ends with edits in the area, so it must be fast.
  Run it once and time it; if it takes more than about 2 minutes, move the
  slow parts (end-to-end, integration) to `verify`.
- `verify`: the full definition of done, run from the repo root. Usually
  what CI runs for that area.
- `testOne`: the test runner command that takes one file (for example
  `pnpm exec vitest run`, `npx jest`, `node --test`, `pytest`). Check it
  works by running it on one existing test file.
- `onEdit`: the formatter's write command and the linter's fix command,
  each with a `match` regex on the file types they handle. Only tools the
  area already uses.
- `ui`: `true` if the area renders UI.
- `openapi`: the OpenAPI file, if the area serves an HTTP API that has one.
- `conventions`: the area's `CLAUDE.md` (or the root one for `path: "."`).

Also propose `baseBranch` (the default branch, as `origin/<name>` if there
is a remote), `order` (dependencies first, e.g. server before web),
`rules` (cross-area rules you can see, e.g. generated client types must be
regenerated after an API change), and `launchConfigs` (the `.claude/launch.json`
configs needed to see the UI).

When an area has no command for something, leave the field out and say
so; don't make one up.

## 3. Propose the conventions sections

For each area's conventions file, check for the sections devflow reads:
`## Structure`, `## Architecture`, `## API` (areas with an HTTP API) and
`## Testing`. For each missing one, draft it from the code: pick the most
representative existing feature and describe what it actually does
(folder layout and where each kind of file goes, the layers and where
business rules live, the API naming and error shape, the test framework,
file placement and fixtures). Cite the files you based it on. Keep each
section short; it's a map, not documentation. Never change what an
existing section says.

## 4. Approve, write, check

Show the user the proposed `.claude/devflow.json` and each conventions
addition, with what you couldn't find. Ask them to approve or change it
(use AskUserQuestion for real choices, such as which areas exist or
whether a slow suite belongs in `check`).

On approval:

1. Write `.claude/devflow.json` with
   `"$schema": "https://raw.githubusercontent.com/rakgithub/claude-plugins/main/plugins/devflow/devflow.schema.json"`
   as its first field, and add the approved conventions sections.
2. Tell the user that devflow's hooks run the commands in this file, and
   to review it like any other hook configuration.
3. If `.claude/settings.json` doesn't enable devflow, show the snippet
   from the devflow README so the team gets it too; don't edit
   `settings.json` without asking.

End by suggesting `/devflow:prd` for a new requirement, `/devflow:feature`
for a small change, or `/devflow:bugfix` for a bug.
