---
name: implement-in-worktree
description: Create an isolated git worktree, implement a GitHub issue or a free-text description in it, commit, push, open a PR, and clean up the worktree. Use when the user says "do this in a worktree", "implement issue #N in a worktree", or /implement-in-worktree.
disable-model-invocation: true
---

# Implement in worktree

Take a GitHub issue or a free-text description from spec to open PR, fully
isolated from the shared working tree: create a new git worktree, implement
the work there, commit, push, open a PR, report its URL, then remove the
worktree. Assumes `gh` is authenticated. Project conventions (commit style,
required checks) come from the project's `AGENTS.md` or `CLAUDE.md`.

Unlike `implement-issue` (which works directly in the shared checkout) or
`ship-pr` (which ships whatever is already changed there), this skill's job
is isolation: nothing it does touches the main working tree, so it's safe to
run alongside other work in progress.

Args (required, `$ARGUMENTS`): a GitHub issue number/URL, or a free-text
description of what to build. If missing, ask for one rather than guessing.

## Steps

1. **Resolve the input.**
   - Base branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
     (usually `main`). Below, `<base>` means that branch.
   - If `$ARGUMENTS` is an issue number or URL: `gh issue view <issue> --json
     title,number,body` to get the spec. Derive the branch slug and PR title
     from the issue title, and plan to include `Closes #<issue-number>` in
     the PR body.
   - Otherwise: treat `$ARGUMENTS` as the spec directly, and derive a
     kebab-case slug from it for the branch name and commit/PR title.
   - Pick the Conventional Commit type (`feat`/`fix`/`chore`/...) the spec
     implies — used for both the branch prefix and the commit subject.

2. **Enter an isolated worktree.**
   - If the session is already inside a worktree, stop and ask how to
     proceed rather than nesting one.
   - Name it `<type>-<slug>` (append `-<issue-number>` when working an
     issue, e.g. `fix-login-redirect-142`).
   - If an `EnterWorktree` tool is available (Claude Code), call it with that
     name; it creates the worktree on a new branch and moves the session
     into it.
   - Otherwise (e.g. Codex): `git fetch origin <base>`, then
     `git worktree add ../<repo>-<name> -b <type>/<slug> origin/<base>`, and
     run every following step from inside that directory.

3. **Implement the spec.** Install dependencies in the worktree if the
   project needs them. Build the resolved spec, running typechecking and
   targeted tests as you go.

4. **Verify.** Run the project's checks. Find them in `AGENTS.md`,
   `CLAUDE.md`, `CONTRIBUTING.md`, or the package scripts: lint, format
   check, tests, build, and any pre-commit or audit gate the project
   requires. Fix failures; report any you cannot fix.

5. **Commit.** Stage the relevant files and commit with the project's commit
   convention (Conventional Commits if none is stated) plus the attribution
   footer this session's instructions specify.

6. **Push.** `git push -u origin <branch>` from inside the worktree.

7. **Open the PR and share the link.**
   `gh pr create --base <base> --head <branch> --title "<title>" --body
   "<summary of the change and why>"`, including `Closes #<issue-number>` in
   the body when the input was an issue. Reply with the PR URL.

8. **Clean up the worktree.** Only after the PR is open: the work is safe on
   `origin/<branch>` and in the PR.
   - With `ExitWorktree`: `action: "remove"` and `discard_changes: true`
     (it otherwise refuses because the branch is not merged yet, which is
     expected).
   - Otherwise: leave the worktree directory, then
     `git worktree remove ../<repo>-<name>`.

## Guardrails

- Outward-facing (pushes to GitHub, opens a PR): ask before proceeding if
  the issue/description is ambiguous, an issue already has an open PR, or
  the session is already inside a worktree.
- Never commit directly to `<base>`, never force-push, and never merge the
  PR — this skill only opens it.
- Don't remove the worktree until the PR is successfully opened. If
  something fails earlier, leave the worktree in place so the work isn't
  lost.
