---
name: ship-pr
description: Branch off the default branch, commit the current diff, push it, open a GitHub PR, and hand back the PR link. Use when the user says "ship this", "open a PR", "push this to GitHub", "create a branch and PR", or /ship-pr.
---

# Ship PR

Turn whatever changed in this working tree into a pushed branch and an open
GitHub PR against the default branch, then report the PR URL back to the user.
Assumes `gh` is authenticated. Project conventions (commit style, required
checks) come from the project's `AGENTS.md` or `CLAUDE.md`.

Args (optional, `$ARGUMENTS`): a short description of the change, used as the
branch slug, commit subject, and PR title if given. If omitted, derive all
three from the diff itself.

## Steps

1. **Find the base and see what there is to ship.**
   - Base branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
     (usually `main`). Below, `<base>` means that branch.
   - `git fetch origin <base>`
   - `git status --porcelain` and, if already on a non-base branch,
     `git log origin/<base>..HEAD --oneline`.
   - Ship either uncommitted working-tree changes, or existing local commits
     not yet on `origin/<base>` — whichever is present. If both are empty,
     stop and tell the user there is nothing to ship; do not open an empty
     PR.

2. **Pick a branch name.** kebab-case, `<type>/<short-slug>` (e.g.
   `feat/hero-availability-info`, `fix/footer-links`), matching the
   Conventional Commit type the change implies. Use the branch already
   checked out only if it was created off `<base>` for this exact change and
   has no unrelated history; otherwise create a fresh one from `origin/<base>`.

3. **Branch from the base without losing work.**
   - If shipping uncommitted changes: `git stash -u`, create the branch from
     `origin/<base>` (`git checkout -b <branch> origin/<base>`), then
     `git stash pop`.
   - If shipping existing local commits from another branch: create the new
     branch from `origin/<base>`, then bring the commits over with
     `git cherry-pick <merge-base>..<old-branch>`. Confirm with the user
     before rewriting a branch they may already be using elsewhere.
   - Never commit directly to `<base>`.

4. **Run the project's checks.** Find them in `AGENTS.md`, `CLAUDE.md`,
   `CONTRIBUTING.md`, or the package scripts: lint, format check, tests, and
   any pre-commit or audit gate the project requires. Run the narrowest set
   that covers the diff. Fix failures; report any you cannot fix rather than
   skipping past them.

5. **Commit.** Stage the relevant files (never `git add -A` blindly if
   unrelated changes are sitting in the tree) and commit with the project's
   commit convention (Conventional Commits if none is stated:
   `<type>[scope]: <imperative lowercase summary>`), following whatever
   attribution footer this session's instructions currently specify.

6. **Push.** `git push -u origin <branch>`.

7. **Open the PR.** `gh pr create --base <base> --head <branch> --title
   "<title>" --body "<summary of the change and why>"`, again with whatever
   PR-body footer this session's instructions currently specify. Write the
   body from the actual diff — what changed and why — not a restatement of
   the commit subject.

8. **Share it.** Reply with the PR URL `gh pr create` prints (or fetch it via
   `gh pr view <branch> --json url -q .url` if needed) so the user has it
   directly, not just "done."

## Guardrails

- This workflow pushes to GitHub and opens a PR — outward-facing, so if
  anything about scope or destination branch is ambiguous (e.g. multiple
  unrelated changes sitting in the tree, or an existing branch with history
  that doesn't obviously belong to this change), ask before proceeding
  rather than guessing.
- Do not force-push, rewrite a branch the user is actively working on
  without confirming first, or merge the PR — this skill only opens it.
