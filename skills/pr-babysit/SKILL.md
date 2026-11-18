---
name: pr-babysit
description: Watch a pull request until CI is green and it has no merge conflicts, fixing CI failures and conflicts on the way. Use when the user says "babysit this PR", "get PR #N green", "watch CI and fix it", or /pr-babysit.
argument-hint: "<pr-number|pr-url>"
disable-model-invocation: true
model: sonnet
---

# PR Babysit

Babysit one pull request until it is **settled**: every CI check passes and
GitHub reports no conflict with the PR's base branch. Each round, resolve
conflicts, watch CI, and fix or rerun what fails. Uses only `gh` and git, so
it works in any project, in the CLI and in headless runs. Assumes `gh` is
authenticated. (In the Claude desktop app, Auto-fix on a bound PR does the
same job.)

Project conventions come from the project's `AGENTS.md`, `CLAUDE.md` or
`CONTRIBUTING.md`: commit style, required checks, package manager. Follow
them for every commit. Where they say nothing, use Conventional Commits.

Invoking this skill is permission to push to the PR's own head branch, and
only that branch: plain `git push`, never a force-push, never the base
branch.

Args (required, `$ARGUMENTS`): a PR number or URL. If missing, ask for one;
the current branch is not a fallback.

## 1. Read the PR

```bash
gh pr view <pr> --json number,url,state,headRefName,baseRefName,isCrossRepository
```

Stop and report when the PR is merged or closed, or comes from a fork
(`isCrossRepository`: you cannot push to it). Below, `<head>` is
`headRefName` and `<base>` is `baseRefName`.

Done when you know the PR number, URL, head branch and base branch.

## 2. Get a checkout

| State | Where to work |
| --- | --- |
| On `<head>`, clean tree | Here. `git pull --ff-only` to catch up. |
| On `<head>`, uncommitted changes | Stop and ask the user: their work must stay out of your commits. |
| On any other branch | A temporary worktree: `git fetch origin <head>`, then `git worktree add <scratch-dir>/pr-<number> <head>`, then install dependencies there. |

To install dependencies, use what the project's docs say. Otherwise pick by
lockfile: `pnpm-lock.yaml` → `pnpm install`, `yarn.lock` → `yarn install`,
`package-lock.json` → `npm ci`, `bun.lock`/`bun.lockb` → `bun install`,
`uv.lock` → `uv sync`, `poetry.lock` → `poetry install`, `Gemfile.lock` →
`bundle install`, `go.mod` / `Cargo.toml` need nothing up front.

Use the session's scratch or temp directory for `<scratch-dir>`; never put
the worktree inside the repository's tracked tree.

Done when you are in a clean checkout of `<head>`, level with
`origin/<head>`.

## 3. Find the project's checks

Before the first fix, learn how to run locally what CI runs. Look, in this
order, at:

1. `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` (a "definition of done",
   "checks" or "before you push" section).
2. The CI workflow files (`.github/workflows/*.yml` or the equivalent): the
   commands each job runs.
3. Task runners: `package.json` scripts, `Makefile`, `justfile`,
   `Taskfile.yml`, `pyproject.toml`, etc.

Note the command for each CI check name (format, lint, types, tests, build,
…). Done when you can map each check to a local command, or know which ones
only run in CI.

## 4. Babysit

Repeat this round until the PR settles or a stop condition fires. Keep a
tally of fix rounds per failing check name.

1. **Conflicts.** `gh pr view <pr> --json mergeable`.
   - `UNKNOWN`: GitHub is still computing it. Wait a minute and ask again.
   - `CONFLICTING`: `git fetch origin` and `git merge origin/<base>`.
     Resolve the conflicts (use a merge-conflict skill if one is
     available), keeping both sides' intent, then run the checks that cover
     the touched files.
   - Merge, never rebase: a rebase would need a force-push.
   - A branch that is only behind `<base>`, without a conflict, stays as it
     is.
2. **Watch.** Run `gh pr checks <pr> --watch` and wait for it to exit. Run
   it in the background if your harness supports that; otherwise run it in
   the foreground with a long timeout. Right after a push, checks can take a
   minute to register; when it reports none, wait and rerun it. Exit `0`
   means green: skip to step 5.
3. **Triage each failed check.** List them with `gh pr checks <pr>`. Read
   the log with `gh run view <run-id> --log-failed` and compare the failure
   with the PR's diff (`git diff origin/<base>...HEAD`). Sort it into one
   bucket:
   - **Caused by the PR** (format, lint, types, tests, build, any other
     project gate): reproduce it with the local command from section 3 and
     fix it within the PR's scope.
   - **Flaky or infrastructure** (runner error, timeout, network, rate
     limit, a test that passes locally on the same commit):
     `gh run rerun <run-id> --failed`, once per check. A second failure
     moves it to the PR bucket.
   - **Needs a decision**: the fix changes product behaviour, reaches
     outside the PR's scope, changes a database migration or public API in
     a way the diff does not already, or needs a secret or setting you
     cannot change. Stop.
4. **Push.** Run the project's full local checks (section 3) and make them
   pass. Commit the fixes or the merge: one commit per round, in the
   project's commit style, typed for what changed (`style:` for formatting,
   `fix:` for a broken test or type, and so on), with the attribution footer
   this session's instructions specify. Then
   `git push origin HEAD:<head>` and start the next round. A rerun with no
   code change needs no push.
5. **Settle.** Green, and `mergeable` is `MERGEABLE`: wait 5 minutes (a
   background `sleep 300` where you can) and check both again, since
   `<base>` can move. Still settled: go to section 5. Otherwise start
   another round.

Stop conditions, each ending in the report:

- A check has failed after 3 fix rounds.
- A failure needs a decision.
- The checks keep failing locally after your fix and you cannot find why.
- The PR gets merged or closed while you watch.

## 5. Clean up and report

Remove a worktree you created with `git worktree remove <path>`. Leave the
user's own checkout as you found it. Then reply with:

- the PR URL;
- the end state: **settled**, **gave up** (which check, and what the 3
  rounds tried), **needs a decision** (what, and the options you see) or
  **closed**;
- the commits you pushed (short SHA and subject) and the reruns you
  triggered.

The report goes in chat only; post nothing on the PR.

## Guardrails

- Push only to the PR's head branch. Never force-push, never push to or
  commit on the base branch, never merge the PR, never enable auto-merge.
- Never skip, disable or weaken a check, test or lint rule to make CI pass.
- Never touch CI secrets, branch protection or repository settings.
- Keep fixes inside the PR's scope; anything larger is a decision for the
  user.
