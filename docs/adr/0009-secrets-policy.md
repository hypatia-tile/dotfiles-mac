# 0009. Secrets never enter the repository

- Status: Accepted
- Date: 2026-07-13

## Context

Discovery necessarily walks paths containing credentials (`~/.config/gh`,
SSH keys, tokens). The repository is public (ADR 0010), so a single leaked
commit is unrecoverable in practice.

## Decision

- No secrets in this repository, encrypted or otherwise. sops-nix/agenix is
  explicitly deferred to a future ADR if ever needed.
- Discovery records secret-bearing paths by filename only; contents are never
  read.
- Preventive guards: `.gitignore` patterns for common secret files, a
  secret-pattern check inside the `migration-check` skill, and a gitleaks job
  in CI (ADR 0012).

## Consequences

- The strongest possible posture ("not present") at zero operational cost.
- Anything genuinely needing a secret (none identified so far) must be
  provisioned outside this repository.
