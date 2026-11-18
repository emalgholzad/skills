---
name: comment-cleaner
description: Audit code comments across a codebase or target directory, treat explanatory comments as code smells for underlying workarounds, refactor away workarounds, extract architectural decisions into ADRs or tests, and delete redundant comments. Use when the user asks to clean up comments, audit comments, ban or reduce comments, remove comment clutter, or refactor comment-masked workarounds.
argument-hint: "[path]"
---

# Comment Cleaner

Audit the code comments in a codebase or directory, treat each explanatory
comment as a smell for an underlying workaround, refactor the code so the
comment becomes unnecessary, keep genuine non-code knowledge in tests or
ADRs, and delete the rest.

Args (optional, `$ARGUMENTS`): the directory, files or PR to audit. Without
one, audit the whole repository.

## Philosophy

Comments are a safety valve that lets workarounds proliferate. An
explanatory comment is often a **fig leaf**: it covers an awkward API, a
missing abstraction or a fragile hack that should be redesigned instead.
Comments that restate the code add maintenance surface and go stale.

The test for every comment: _if comments were banned in this folder, how
would we design the code so this comment isn't needed?_

## 1. Audit the comments in scope

Collect every comment in scope, from tracked files only (`git ls-files`).
Skip generated files, vendored and third-party code, lockfiles, build
output and minified assets. Use `cloc` or `tokei` for counts when
installed; otherwise search with the comment syntax of each language in the
repo.

Measure **comment density** per folder: comment lines ÷ total lines.

Done when you have a list of every comment in scope (`file:line` and text)
and the density for each folder.

## 2. Classify every comment

Put each comment in exactly one bucket. Be relentless: "it explains why" is
not a reason to keep a comment. Ask whether the code can be redesigned so
the _why_ disappears.

| Bucket | Applies to | Action |
| --- | --- | --- |
| **Delete** | Restates what the code already says. Session notes an agent left for itself ("changed during the X refactor"). Stale or wrong comments. Commented-out code. | Delete it. |
| **Refactor** | Explains a library quirk, hack or defensive workaround. | Wrap the quirk in an adapter, helper or typed API so the call site explains itself; then delete the comment. |
| | Explains a magic string, type assertion or implicit contract. | Encode the contract in types, schemas, constants or names; then delete the comment. |
| **Test** | Explains a subtle edge case, race condition or ordering constraint. | Write a test whose name states the constraint and whose assertion enforces it; then delete the comment. |
| **ADR** | Records an architectural tradeoff, persistence contract or hard-to-reverse system constraint that code and tests cannot express. | Move it into an ADR or a glossary entry; then delete the comment. |
| **Keep** | A compiler or linter directive (`@ts-expect-error`, `eslint-disable`, `# type: ignore`, `//go:build`) that better typing cannot remove, with a short reason. A required license header. JSDoc/docstrings on public library entry points, when the project requires them. | Keep it. These are the only exceptions. |

Done when every comment from step 1 has a bucket, and every Refactor, Test
and ADR item names its concrete target: the helper or type to introduce,
the test name, or the ADR title.

## 3. Propose an execution plan

Present the findings grouped by bucket, with file counts, comment-line
counts and the concrete proposal for each Refactor, Test and ADR item. Order
the work in these batches:

1. Delete clutter, stale comments and commented-out code.
2. Add tests for the edge-case and race-condition comments, then remove
   those comments.
3. Refactor the workarounds into clean abstractions, then remove those
   comments.
4. Write ADRs or glossary entries for the architectural decisions, then
   remove those comments.
5. Enforce the standard: a lint rule (for example a max comment density, or
   banned `TODO`/`HACK` markers) or a folder-level no-comments rule in
   `AGENTS.md`/`CLAUDE.md`.

For ADRs, follow the project's existing ADR folder and format. If there is
none, propose `docs/adr/NNNN-<kebab-title>.md` with Context, Decision and
Consequences sections.

If the user asked to apply the changes directly, continue to step 4.
Otherwise, stop and wait for them to confirm the plan or narrow it.

## 4. Execute and verify

Apply the plan one batch at a time, each batch a focused, reviewable change.
After each batch, run the project's typechecker, linter and test suite
(from `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` or the package scripts)
and confirm behavior is unchanged before you start the next batch. A new
test from batch 2 must pass against the current code: it captures existing
behavior.

Done when every batch is applied with the checks green, and you report:
comment density before and after, the counts per bucket, the helpers,
tests and ADRs you added, and the comments you kept with their reasons.

## Gotchas

- **Too lenient.** Leaving hundreds of "explains why" comments in place
  defeats the purpose. Apply the ban test from the Philosophy to each one.
- **Losing constraint knowledge.** Before you delete a comment about a race
  condition, persistence contract, or hardware or browser quirk, capture it
  in a test name, an adapter or an ADR.
- **Breaking directives.** Remove a compiler, bundler or linter pragma only
  after you fix the warning or error it suppresses.
