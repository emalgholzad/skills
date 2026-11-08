---
name: implement-issue
description: Branch off the default branch, pull latest, implement a GitHub issue, commit and push, open a PR, and hand back the PR link. Use when the user says "implement issue #N", "work this issue", "pick up issue #N", or /implement-issue.
disable-model-invocation: true
---

# Implement issue

Take a GitHub issue from ticket to open PR: fresh branch off the default
branch, implement the issue directly, then commit, push, open a PR, and report
its URL. Assumes `gh` is authenticated. Project conventions (commit style,
required checks) come from the project's `AGENTS.md` or `CLAUDE.md`.

Args (required, `$ARGUMENTS`): an issue number or URL. If missing, ask for
one rather than guessing which issue.

## Steps

1. **Branch off the base, pulling latest first.**
   - Base branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
     (usually `main`). Below, `<base>` means that branch.
   - `git status --porcelain` — if the working tree is dirty, stop and ask
     the user how to handle it (stash, commit, or discard) rather than
     branching over uncommitted work.
   - `git checkout <base> && git pull origin <base>`.
   - `gh issue view <issue> --json title,number` to get the issue title, then
     create a kebab-case branch `<type>/<short-slug>-<issue-number>` (e.g.
     `fix/login-redirect-142`), matching the Conventional Commit type the
     issue implies. `git checkout -b <branch>`.
   - Never commit directly to `<base>`.

2. **Implement the issue.** Fetch the issue's full spec with
   `gh issue view <issue> --json title,body` and implement the work it
   describes. Run typechecking and single test files regularly, and the full
   test suite once at the end; do not shortcut it.

3. **Verify, then commit and push.**
   - Run the project's checks. Find them in `AGENTS.md`, `CLAUDE.md`,
     `CONTRIBUTING.md`, or the package scripts: lint, format check, tests,
     build, and any pre-commit or audit gate the project requires. Fix
     failures; report any you cannot fix rather than skipping past them.
   - Commit with the project's commit convention (Conventional Commits if
     none is stated) and whatever attribution footer this session's
     instructions currently specify. Confirm with `git status --porcelain`
     that nothing is left uncommitted.
   - `git push -u origin <branch>`.

4. **Open the PR and share the link.**
   - `gh pr create --base <base> --head <branch> --title "<title>" --body
     "<summary of the change and why>"`, including `Closes #<issue-number>`
     in the body and whatever PR-body footer this session's instructions
     currently specify.
   - Reply with the PR URL `gh pr create` prints (or
     `gh pr view <branch> --json url -q .url` if needed) so the user has it
     directly, not just "done."

## Guardrails

- This workflow pushes to GitHub and opens a PR — outward-facing, so if the
  issue is ambiguous, already has an open PR, or the working tree has
  unrelated changes sitting in it, ask before proceeding rather than
  guessing.
- Do not force-push, rewrite a branch the user is actively working on
  without confirming first, or merge the PR — this skill only opens it.
