---
name: review
description: Reviews a branch or pull request with devflow's reviewers and the repo's verify commands, or works through the review comments on a pull request (agree, fix test-first, or reply with evidence). Use when the user runs /review for devflow, asks to review a PR or branch someone wrote, or asks to address PR review comments.
argument-hint: [branch | PR number or URL] [comments]
---

# /review — review a branch or PR, or answer its review

Before anything else, read `.claude/devflow.json` (areas, commands,
`baseBranch`, `specsDir`) and the root `CLAUDE.md`. If the config is
missing, stop and tell the user to add one (run `/devflow:init`).

Input: nothing (the current branch), a branch name, or a PR number or
URL. With `comments`, work through the PR's review comments instead of
reviewing it.

## Get the code

The reviewers read the checked-out branch. If the target isn't checked
out:

- With uncommitted changes in this checkout, don't switch; suggest
  running this in a new worktree session instead.
- Otherwise, ask before switching (`gh pr checkout <n>` or
  `git switch <branch>`), note the branch you were on, and switch back
  when done.

For a PR, read its description and linked issue (`gh pr view <n>`). If
the diff touches a spec folder under `specsDir`, or the PR names one, use
it.

## Review mode

1. Run the `devflow:code-reviewer` subagent (with the spec folder, if
   any) and, if any area with `"ui": true` changed, `devflow:ui-reviewer`,
   in parallel. Meanwhile run the `verify` command of each touched area.
2. Check each finding against the code before reporting it; drop the
   ones that don't hold up and say how many you dropped.
3. Report: a one-paragraph summary of the change, the findings as
   blocker / should-fix / nit with `file:line`, the verify results, and a
   verdict (ready, ready after fixes, needs rework).
4. For a PR, offer to post the findings as review comments. Post only if
   the user says yes, and show them the exact text first. Never approve
   or request changes on their behalf unless they say which.

## Comments mode

1. Fetch the PR's unresolved review comments and threads
   (`gh pr view <n> --json reviews,comments` and
   `gh api repos/{owner}/{repo}/pulls/<n>/comments`).
2. For each, decide: **agree** (what you'd change), **disagree** (with
   evidence: the code, test, spec or convention that supports the current
   version), or **question** (what you'd ask). Show the table and ask the
   user to confirm or change it before touching code.
3. Fix the agreed ones. A behaviour change goes test-first through the
   `devflow:test-writer` subagent, as in `/devflow:feature`. Run the touched
   areas' `verify` until green, then the `devflow:code-reviewer` subagent on
   the new changes, and handle its findings as in `/devflow:feature`'s
   Review.
4. Draft a reply to each comment: what changed (with `file:line`) or why
   not. Post replies only if the user says yes, after showing them the
   text.
5. Propose conventions rules from what reviewers had to point out, as in
   `/devflow:feature`'s Hand back.

Do not commit or push; the user does that.
