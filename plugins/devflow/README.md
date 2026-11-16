# devflow

A spec-driven development workflow for Claude Code. The plugin holds the
**process**; each repo describes its own **facts** in `.claude/devflow.json`.

```
/devflow:prd      clarify the requirement            -> <specsDir>/<slug>/prd.md
/devflow:design   codebase-grounded design + tasks   -> design.md, tasks.md (you approve)
/devflow:feature  build test-first, task by task     -> code + tests, verify, review
/devflow:bugfix   failing test -> root-cause fix     -> verify, review
```

Small changes can go straight to `/devflow:feature <description>`; it writes
a short spec and plan for approval itself. Use the full chain for vague or
multi-part requirements, and run `/devflow:feature <spec folder>` in a
**new session** after the design is approved.

Agents: `devflow:test-writer`, `devflow:code-reviewer`,
`devflow:ui-reviewer`, `devflow:plan-reviewer`.

Hooks: after every Edit/Write, the owning area's `onEdit` steps run on the
file; before a turn ends, each changed area's `check` must pass. Both do
nothing in a repo without `.claude/devflow.json`. They need `jq`.

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

2. Add `.claude/devflow.json` (below).
3. Keep stack rules (structure, conventions, testing rules) in each area's
   conventions file, usually that area's `CLAUDE.md`. The skills and agents
   read and follow it.

## `.claude/devflow.json`

| Field | Meaning |
|---|---|
| `specsDir` | Where spec folders live. Default `docs/specs`. |
| `baseBranch` | What branches and reviews diff against. Default `origin/main`. |
| `areas[]` | The parts of the repo (apps/packages, or one area with `path: "."`). |
| `areas[].name` | Short name used in designs and tasks. |
| `areas[].path` | Folder, relative to the repo root. |
| `areas[].conventions` | File with the area's rules (usually its `CLAUDE.md`). |
| `areas[].ui` | `true` if UI changes here should get the ui-reviewer. |
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

Validate before pushing, then bump `version` in `.claude-plugin/plugin.json`:

```bash
claude plugin validate ~/Documents/claude-plugins
```
