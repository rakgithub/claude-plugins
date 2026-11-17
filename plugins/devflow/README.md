# devflow

A spec-driven development workflow for Claude Code. The plugin holds the
**process**; each repo describes its own **facts** in `.claude/devflow.json`.

```
/devflow:init     set devflow up in a repo           -> .claude/devflow.json + conventions sections
/devflow:prd      clarify the requirement            -> <specsDir>/<slug>/prd.md
/devflow:design   codebase-grounded design + tasks   -> design.md, tasks.md (you approve)
/devflow:feature  build test-first, task by task     -> code + tests, verify, review
/devflow:bugfix   failing test -> root-cause fix     -> verify, review
/devflow:refactor pin behaviour -> small safe steps  -> verify, review (no behaviour change)
/devflow:review   review a branch/PR, or its comments -> findings, or fixes + draft replies
```

After a review, `/feature`, `/bugfix` and `/review` propose one-line rules
for the area's conventions file when a reviewer caught something a written
rule would have prevented, so the conventions improve with each change.

Small changes can go straight to `/devflow:feature <description>`; it writes
a short spec and plan for approval itself. Use the full chain for vague or
multi-part requirements, and run `/devflow:feature <spec folder>` in a
**new session** after the design is approved.

Agents: `devflow:test-writer`, `devflow:code-reviewer`,
`devflow:ui-reviewer`, `devflow:plan-reviewer`.

UI work (areas with `"ui": true`) follows the `frontend-design` skill in
`/design`, `/feature`, `/bugfix` and the ui-reviewer. devflow declares
`frontend-design@claude-plugins-official` as a dependency, so installing
devflow installs it too; the area's conventions still win.

Hooks: after every Edit/Write, the owning area's `onEdit` steps run on the
file and the area is recorded as edited by this session. Before a turn
ends, the `check` of each area the session edited must pass; your own
uncommitted work in other areas doesn't trigger it. If a check keeps
failing, the turn is blocked up to 3 times, then ends with a warning shown
to you. Files changed only through Bash aren't tracked. Both hooks do
nothing in a repo without `.claude/devflow.json`. They need `jq`.

Tests are the spec: `/feature` and `/bugfix` never edit a test to make it
pass without your agreement, record every test changed after it went red,
and the code-reviewer blocks tests that no longer prove what they name.

## Using it in a repo

1. In the repo's `.claude/settings.json` (committed):

   ```json
   {
     "extraKnownMarketplaces": {
       "rakgithub": { "source": { "source": "github", "repo": "rakgithub/claude-plugins" } }
     },
     "enabledPlugins": { "devflow@rakgithub": true }
   }
   ```

   Permissions (allow/deny) stay in the repo's own settings.

2. Run `/devflow:init` to draft `.claude/devflow.json` (below) and the conventions sections; it writes them once you approve.
3. Keep the repo's rules in each area's conventions file, usually that
   area's `CLAUDE.md`. The skills and agents read it, and it wins over
   anything generic in devflow. They look for these sections:

   | Section | What it says | Used by |
   |---|---|---|
   | `## Structure` | Folder tree, where each kind of file goes, and an existing feature to model new ones on. | Plans place every new file by it; reviewers check it. |
   | `## Architecture` | Layers, where business rules live, how modules talk to each other (for example DDD). | `/design` step 3, both reviewers. |
   | `## API` | Naming, pagination, error shape, versioning, idempotency. | Contracts in `/design` and `/feature`. |
   | `## Testing` | Framework, file placement, fixtures, what each kind of code must cover. | test-writer, code-reviewer. |

   A missing `## Structure` or `## Architecture` is inferred from the
   nearest existing feature, and devflow proposes adding it.

HTTP APIs are spec-first. For an area with `openapi` set, `/design` writes
contract changes as OpenAPI, each task that changes an endpoint updates the
OpenAPI file before the code, tests are written from it, and the reviewers
check code and spec agree. Lint the spec in the area's `verify` (for example
`redocly lint`); devflow doesn't install a linter.

## `.claude/devflow.json`

`/devflow:init` drafts this file from the repo. Add
`"$schema": "https://raw.githubusercontent.com/rakgithub/claude-plugins/main/plugins/devflow/devflow.schema.json"`
for validation and completion in your editor
([devflow.schema.json](devflow.schema.json)).

| Field | Meaning |
|---|---|
| `specsDir` | Where spec folders live. Default `docs/specs`. |
| `baseBranch` | What branches and reviews diff against. Default `origin/main`. |
| `areas[]` | The parts of the repo (apps/packages, or one area with `path: "."`). |
| `areas[].name` | Short name used in designs and tasks. |
| `areas[].path` | Folder, relative to the repo root. |
| `areas[].conventions` | File with the area's rules (usually its `CLAUDE.md`). |
| `areas[].ui` | `true` if UI changes here should get the ui-reviewer. |
| `areas[].openapi` | The OpenAPI file (relative to the repo root) that is the source of truth for this area's HTTP API. Omit for areas without one. |
| `areas[].onEdit[]` | `{ "match": regex on the file path, "run": command }`, run from `path` with the file in `$FILE` after each edit. |
| `areas[].check` | Fast checks, run from `path` before a turn ends when the area has changes. |
| `areas[].verify` | Full definition of done, run from the repo root. |
| `areas[].testOne` | Runs one test file (appended), from `path`. |
| `order` | Build order when several areas change, e.g. `["server", "web"]`. |
| `rules` | Cross-area rules every plan and review must respect. |
| `launchConfigs` | `.claude/launch.json` configs to start for browser checks. |

The commands in this file are executed by the hooks, exactly like hook
commands in `settings.json`, so treat changes to it with the same care.

Example (pnpm monorepo, React web + Express API):

```json
{
  "specsDir": "docs/specs",
  "baseBranch": "origin/main",
  "areas": [
    {
      "name": "server",
      "path": "apps/server",
      "conventions": "apps/server/CLAUDE.md",
      "openapi": "apps/server/openapi.yaml",
      "onEdit": [
        { "match": "\\.(ts|js|json|md)$", "run": "pnpm exec prettier --write \"$FILE\"" },
        { "match": "\\.(ts|js)$", "run": "pnpm exec eslint --fix --max-warnings 0 \"$FILE\"" }
      ],
      "check": "pnpm lint && pnpm format:check && pnpm typecheck && pnpm test",
      "verify": "pnpm verify:server",
      "testOne": "pnpm exec vitest run"
    }
  ],
  "order": ["server"],
  "rules": [],
  "launchConfigs": []
}
```

## Developing the plugin

Load your local clone instead of the published version:

```bash
claude --plugin-dir ~/Documents/claude-plugins/plugins/devflow
```

Test the hooks (fast, deterministic):

```bash
bash hooks/test-hooks.sh
```

Run the eval suite after changing a skill or agent prompt. Each case is a
real Claude session on the fixture repo in `evals/_fixture/` (a bugfix, a
quick-mode feature, and a review of a branch with planted bugs), graded on
process (tests before code) and outcome. A full run is a few dollars; use
`--runs 1` while iterating. `run.sh` evaluates a copy without the
`frontend-design` dependency, which the sandbox can't resolve.

```bash
bash evals/run.sh --runs 1 -j 3
```

Validate before pushing, then bump `version` in `.claude-plugin/plugin.json`:

```bash
claude plugin validate ~/Documents/claude-plugins
```
