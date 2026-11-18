# Skills

Reusable agent skills for [Claude Code](https://claude.com/claude-code) and
[Codex](https://developers.openai.com/codex). Each skill is a folder with a
`SKILL.md` file under [`skills/`](skills).

## Install

Install everything into the current project:

```bash
npx skills add emalgholzad/skills
```

Install one skill, or install globally for all your projects:

```bash
npx skills add emalgholzad/skills --skill ship-pr
npx skills add emalgholzad/skills -g
```

Get the latest versions:

```bash
npx skills update
```

## Skills

| Skill | What it does |
| --- | --- |
| [`ship-pr`](skills/ship-pr/SKILL.md) | Commit the current diff on a new branch, push, and open a PR. |
| [`pr-babysit`](skills/pr-babysit/SKILL.md) | Watch a PR until CI is green and conflict-free, fixing failures on the way. |
| [`implement-issue`](skills/implement-issue/SKILL.md) | Implement a GitHub issue on a fresh branch and open a PR. |
| [`implement-in-worktree`](skills/implement-in-worktree/SKILL.md) | Same as `implement-issue`, but in an isolated git worktree. |
| [`describe-feature`](skills/describe-feature/SKILL.md) | Turn a feature idea into a short GitHub issue draft. |
| [`comment-cleaner`](skills/comment-cleaner/SKILL.md) | Audit comments, refactor away the workarounds they hide, and move real knowledge into tests or ADRs. |
| [`grill-one-by-one`](skills/grill-one-by-one/SKILL.md) | Interview you one question at a time, in Simplified Technical English. |

## License

[MIT](LICENSE)
