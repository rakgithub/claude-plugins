# claude-plugins

Claude Code plugin marketplace.

| Plugin | What it does |
|---|---|
| [devflow](plugins/devflow/README.md) | Spec-driven workflow: PRD → codebase-grounded design and tasks → test-first build → verify → review. |

Add the marketplace and install:

```bash
claude plugin marketplace add rakgithub/claude-plugins
```

```bash
claude plugin install devflow@rakgithub
```

Then, in each repo, run `/devflow:init` once and use `/devflow:feature`,
`/devflow:bugfix`, `/devflow:refactor` or `/devflow:review`. Or enable it per
repo in `.claude/settings.json`; see the [plugin README](plugins/devflow/README.md#quick-start).
