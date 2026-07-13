---
name: adr-new
description: Scaffold a new ADR in docs/adr with the next sequential number, MADR-lite format, and Status Proposed. Use when the user asks to create, draft, or start an ADR.
---

# adr-new

Create a new Architecture Decision Record for this repository.

## Steps

1. Determine the next number: list `docs/adr/`, take the highest `NNNN`
   prefix, add 1, zero-pad to 4 digits.
2. Derive a short kebab-case slug from the decision title (English).
3. Create `docs/adr/NNNN-<slug>.md` from the template below. Date is today
   (YYYY-MM-DD). Content in English.
4. Fill Context/Decision/Consequences from the conversation; if the decision
   is not yet settled, leave clearly marked `_TBD_` placeholders rather than
   inventing content.

## Rules

- Status is always `Proposed`. **Never** write `Accepted`, `Rejected`, or
  `Superseded` — only the repository owner changes status (ADR 0007).
- Do not renumber or edit existing ADRs; a changed decision gets a new ADR
  that supersedes the old one.
- Do not commit; leave the file for the owner's review.

## Template

```markdown
# NNNN. <Title in imperative or noun phrase>

- Status: Proposed
- Date: YYYY-MM-DD

## Context

<What situation forces a decision? Facts, constraints, prior art.>

## Decision

<The decision, stated actively.>

## Consequences

<What becomes easier, harder, or riskier. Include accepted trade-offs.>
```
