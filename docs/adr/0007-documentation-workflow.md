# 0007. Documentation workflow: MADR-lite ADRs plus a requirements file

- Status: Accepted
- Date: 2026-07-13

## Context

The migration needs lightweight but durable decision records, and a home for
cross-cutting requirements (e.g. "all artifacts in English") that don't
belong to any single ADR.

## Decision

- ADRs live in `docs/adr/NNNN-slug.md` with sequential numbering and a
  MADR-lite format: Status / Date / Context / Decision / Consequences.
- New ADRs always start with `Status: Proposed`. Only the repository owner
  promotes an ADR to Accepted (or rejects it).
- Cross-cutting requirements live in `docs/requirements.md` and reference the
  ADRs that realize them.
- The `adr-new` skill scaffolds ADRs to keep numbering and format consistent.

## Consequences

- Decisions are auditable without heavyweight tooling.
- The old repo's ADRs 0001–0004 remain as historical context in the archived
  repository; this repository starts its own sequence.
