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

Or enable it per repo in `.claude/settings.json`; see the plugin README.
