# 0004. Hostname-keyed configurations with shared modules

- Status: Accepted
- Date: 2026-07-13

## Context

There is currently one target machine (`Kazukis-MacBook-Air`, Apple Silicon,
`aarch64-darwin`). Future Macs are plausible but not planned.

## Decision

`darwinConfigurations` is keyed by hostname, with shared functionality in
common modules so a second host is an additive change, not a refactor.
`aarch64-darwin` remains the only supported system; no Intel or Linux
abstraction is introduced.

## Consequences

- Near-zero cost now; adding a machine later means adding a host entry and
  host-specific overrides only.
- CI builds every attribute of `darwinConfigurations`, so it stays
  host-count-agnostic (ADR 0012).
