---
name: adr-new
description: Scaffold a new ADR in docs/adr with the next sequential number, MADR-lite format, and Status Proposed. Use when the user asks to create, draft, or start an ADR.
---

# adr-new

Create a new Architecture Decision Record for this repository.

## Steps

1. Find the issue the decision starts from (ADR 0035): it records the
   problem before the solution was chosen. Ask the owner for its number. If
   there is none — a decision reached in conversation — file one first that
   states the problem and what was agreed.
2. Determine the next number: list `docs/adr/`, take the highest `NNNN`
   prefix, add 1, zero-pad to 4 digits.
3. Derive a short kebab-case slug from the decision title (English).
4. Create `docs/adr/NNNN-<slug>.md` from the template below. Date is today
   (YYYY-MM-DD). Content in English.
5. Fill Context/Decision/Consequences from the conversation, citing the issue
   from step 1 as `#N` in Context. If the decision is not yet settled, leave
   clearly marked `*TBD*` placeholders rather than inventing content.

## Rules

- Emphasis is asterisks, not underscores: markdownlint's MD049 fails a
  `_TBD_`, and a draft that cannot pass `preflight` is not a draft.
- Status is always `Proposed`. **Never** write `Accepted`, `Rejected`, or
  `Superseded` — only the repository owner changes status (ADR 0007).
- Do not renumber or edit existing ADRs; a changed decision gets a new ADR
  that supersedes the old one.
- A new ADR cites at least one issue. ADR 0032's step 5-3 check will fail one
  that does not (#208).
- Commit the draft on a feature branch like any other change (ADR 0036). The
  owner reviews it in the PR, and only the owner changes its status.

## Template

```markdown
# NNNN. <Title in imperative or noun phrase>

- Status: Proposed
- Date: YYYY-MM-DD

## Context

<What situation forces a decision? Facts, constraints, prior art. Cite the
issue it starts from as #N.>

## Decision

<The decision, stated actively.>

## Consequences

<What becomes easier, harder, or riskier. Include accepted trade-offs.>
```
