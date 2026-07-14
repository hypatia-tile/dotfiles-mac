# 0016. Introduce Nix garbage collection

- Status: Proposed
- Date: 2026-07-15

## Context

Since the cutover (ADR 0015), this flake is the single source of truth and
every `darwin-rebuild switch` adds a system generation, a Home Manager
generation, and new store paths. Nothing collects garbage today: the store
and the generation lists grow without bound.

The usual answer — nix-darwin's `nix.gc.automatic` (and `nix.optimise`) —
is not available here. Nix is installed via the Determinate installer and
`nix.enable = false` (`modules/darwin/nix.nix`), which makes the entire
nix-darwin Nix-management module inert, including its GC scheduling. The
effective user configuration is the HM-managed `~/.config/nix/nix.conf`
(flake-design §4), which currently only enables flakes.

Candidate mechanisms:

- a launchd job declared in this flake (nix-darwin's `launchd` modules
  still work with `nix.enable = false`) running
  `nix-collect-garbage --delete-older-than <N>`;
- whatever scheduled-cleanup facility Determinate Nix (`determinate-nixd`)
  itself provides, if any;
- a documented manual cadence in `docs/operations.md`, with no automation.

Constraint: old generations are the rollback mechanism (runbook §3). Any
retention window bounds how far back a generation-level rollback can
reach; in particular it puts an expiry date on the pre-cutover legacy
generation (ADR 0015), after which rolling back to the legacy regime
means the legacy repositories' dot-link path (runbook layer 2), not a
generation switch.

Two further mechanical facts shape the design:

- Deleting old *system* profile generations requires root, but the user's
  profiles — including Home Manager generations under
  `~/.local/state/nix/profiles` — belong to the user and are not touched
  by a root-run `nix-collect-garbage`. Complete pruning therefore needs
  both a root and a user run.
- `auto-optimise-store = true` has a history of store corruption on macOS
  (NixOS/nix#7273), so hard-link optimisation should not be switched on
  as a side effect of this decision.

## Decision

Introduce automated garbage collection, declared in this flake as two
launchd jobs (nix-darwin's `launchd` modules work regardless of
`nix.enable = false`):

- `launchd.daemons.nix-gc` — runs
  `nix-collect-garbage --delete-older-than 30d` as root: prunes old
  system-profile generations and collects unreachable store paths.
- `launchd.user.agents.nix-gc` — runs the same command as the owner's
  user: prunes the user's profile and Home Manager generations so they
  stop pinning store paths.

Schedule: weekly, via `StartCalendarInterval` (Saturday 10:00 local).
launchd runs a missed interval at the next opportunity after wake, which
suits a laptop that is often asleep — this is why launchd is used
directly rather than a cron-style timer.

Retention: 30 days. Accepted explicitly: once this lands, the
pre-cutover legacy generation will be collected ~30 days after its
creation (2026-07-14), and rollback to the legacy regime from then on is
runbook layer 2 (legacy repos + `dot-link.sh`) only.

Store optimisation is **not** part of this decision: no
`auto-optimise-store`, no scheduled `nix store optimise`. Manual
optimisation stays possible ad hoc; automating it can be a future ADR if
disk pressure warrants.

The implementing change goes through the standard workflow: feature
branch, `migration-check` (build-only), and an `docs/operations.md`
section covering how to run GC manually, how to inspect the launchd jobs
(`launchctl list`, log locations), and the retention/rollback trade-off.

## Consequences

- Disk usage of `/nix/store` stops growing without bound; system, user,
  and Home Manager generations older than 30 days are pruned
  automatically every week.
- The generation-level rollback window shrinks to 30 days, and the
  pre-cutover generation expires with it; rolling back further means
  rebuilding from git history or the legacy dot-link path. This is the
  accepted trade-off.
- The first rebuild after a GC run may re-download or rebuild collected
  paths, so it can be slower.
- Two launchd jobs become part of the system closure and show up in
  closure diffs; `docs/operations.md` gains a GC section maintained
  alongside them.
- Store optimisation remains manual; hard-link savings are forgone until
  a future decision revisits it.
