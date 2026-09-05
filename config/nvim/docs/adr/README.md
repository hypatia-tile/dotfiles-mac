# Architecture Decision Records

Decisions about this Neovim configuration that are not obvious from the
code itself. One file per decision, in English.

- Naming: `NNNN-kebab-case-title.md`, numbered sequentially from `0001`.
- Format: copy `template.md`.
- A superseded ADR is never deleted; set its status to
  `Superseded by NNNN` and add the new one.
- ADRs are documentation, not a gate: they record decisions but do not
  block changes. Reserve them for decision-class changes (policy,
  structure, tool adoption); day-to-day configuration edits need none.
