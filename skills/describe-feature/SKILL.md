---
name: describe-feature
description: Turn a feature idea or conversation into a short, outcome-focused GitHub Issue draft, the step before /to-spec. No interview, no implementation.
disable-model-invocation: true
---

# Describe Feature

Turn the user's feature idea and the conversation so far into a GitHub Issue draft. Work only from what you already have: skip the interview, and write unknowns down instead of asking about them. The draft describes the outcome; `/to-spec` later turns it into a technical spec.

## Process

1. **Read context.** Read the project's glossary and product docs if they exist (for example `CONTEXT.md`, `docs/`, or `README.md`). Done when the title and wording use the project's own terms.
2. **Pick one feature.** Describe it from the user's perspective, in plain language, as outcomes rather than technical design. If the idea holds several features, draft the core one and list the others below the draft as candidates for their own `/describe-feature` runs.
3. **Write the draft** with the template below. Every acceptance criterion is a user-visible behavior someone could observe and test. Every statement traces back to the user or the context; a gap that would change the feature goes under Open Questions.
4. **Return the draft** as raw markdown in a fenced `markdown` block, ready to paste into GitHub. Stop there.

Publish only when the user asks: create the issue with the H1 as its title, the rest as its body, and the issue type and labels the project's issue-tracker docs ask for (for example `docs/agents/issue-tracker.md`). Without such docs, use no labels.

## Template

```markdown
# <Feature title>

## Description

<Who needs this, what they need, and why it matters. One short paragraph.>

## Acceptance Criteria

- [ ] <Expected user-visible behavior>
- [ ] <Expected user-visible behavior>
- [ ] <Important edge case or permission, if relevant>

## Out of Scope

- <Related work the user or context explicitly excluded>

## Open Questions

- <Missing decision that would change the feature>
```

Include Out of Scope only for exclusions actually stated, and Open Questions only for decisions that would change the feature; omit either section when it would be empty. Leave priority, labels, and technical decisions to later steps.