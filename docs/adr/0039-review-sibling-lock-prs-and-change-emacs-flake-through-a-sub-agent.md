# 0039. Review the sibling repositories' lock PRs from here, and change emacs-flake through a sub-agent

- Status: Proposed
- Date: 2026-11-08

## Context

Two repositories beside this one decide what reaches this Mac, and the
owner wants to work on both from a session here (#346):

- hypatia-tile/nix-packages declares what is installed (ADR 0037). From a
  session here it is changed only through the `nix-packages` sub-agent, and
  `agent-guard` refuses any other write into its checkout (ADR 0038).
- hypatia-tile/emacs-flake builds the patched Emacs and is an input of
  nix-packages, not of this repository.

An Emacs bump therefore reaches this Mac through three weekly lock PRs:
emacs-flake's (Fridays), nix-packages' (Saturdays), and this repository's
move of its `nix-packages` input, which `lock-review` covers. The first two
cannot be reviewed from here today:

- nix-packages' `lock-review` starts with `gh pr checkout`, and its gates run
  through `bin/preflight.sh`, which needs a working tree with that
  repository's hooks installed. Both write into the checkout, which ADR 0038
  keeps from the main session. That repository's lock PRs get no CI, so its
  preflight run is the only evidence one of them has: hypatia-tile/nix-packages#19,
  opened by its workflow, reports no checks.
- A throwaway clone does not help. Installing its hooks means setting
  `core.hooksPath`, which `agent-guard` refuses anywhere (ADR 0032; measured
  on 2026-11-08).
- emacs-flake has no review procedure. Its `update.yml` checks that the
  `frame-transparency` patch applies without fuzz and builds `.#default` into
  hypatia-emacs.cachix.org before it opens the PR. The PR's own `build.yml`
  run waits for the owner's approval (hypatia-tile/emacs-flake#8).
- Neither repository's checks can say what a bump does to this host. Only a
  build of this host with the bumped input can, as `bin/nix-packages-diff.sh`
  does for a nix-packages change.
- emacs-flake's overlay builds the patched Emacs from the consumer's
  nixpkgs, not from its own lock. The host's Emacs is a cache hit only while
  nix-packages' nixpkgs gives the same Emacs derivation that emacs-flake's CI
  built. Building this host with emacs-flake's input moved to an older
  revision gave the same system store path (measured on 2026-11-08, #346).

A review writes nothing that it needs to keep. A sub-agent is the answer to
writes (ADR 0038), so a review needs none.

emacs-flake also has no `AGENTS.md`, Git hooks or preflight, which is what
the `nix-packages` sub-agent commits through. A sub-agent there would have
nothing to check its commits (hypatia-tile/emacs-flake#15).

The owner decided the shape on 2026-11-08: reviews as skills here with no
sub-agent, emacs-flake's gates first, the whole chain covered, and
nix-packages' gates moved into its weekly workflow.

## Decision

- **The emacs-flake and nix-packages lock PRs are reviewed from here by the
  main session, through skills in this repository.** No sub-agent takes part.
  Approving a run and merging stay the owner's, handed over as `! gh …`.
- **A review never writes into a sibling checkout.** It reads the PR with
  `gh`, and it builds and evaluates the PR's head by flake reference,
  `github:hypatia-tile/<repository>/<sha>`. It needs no working tree.
- **A lock PR's gates run in its own repository's workflow, before the PR is
  opened,** as emacs-flake's `update.yml` already does. nix-packages' weekly
  workflow is to do the same (hypatia-tile/nix-packages#20). A review here
  reads that run's result as the gates' evidence. Until the workflow does,
  a nix-packages lock PR reviewed here is reported as having unchecked gates.
- **A review here adds this host's view and restates nothing.** It applies
  the sibling repository's own review procedure where one exists, read from
  that repository, with the substitutions above. For nix-packages, what it
  adds is a build of this host with the bumped input, through
  `--override-input`, the diff against the locked build, and whether
  hypatia-emacs.cachix.org has the Emacs that build needs. It never writes
  `flake.lock`. An emacs-flake lock bump changes nothing here by itself,
  because its overlay builds Emacs from the consumer's nixpkgs; its review
  checks the PR's own run and cache.
- **The chain is reviewed in order:** emacs-flake's PR, then nix-packages',
  then this repository's input move with `lock-review`. Each review says
  which of the later PRs will carry the bump.
- **emacs-flake is changed from here only through an `emacs-flake`
  sub-agent,** shaped as ADR 0038 shapes the `nix-packages` one: it reads that
  repository's `AGENTS.md`, commits through its hooks, runs its preflight,
  and pushes nothing. It is defined only after emacs-flake has those
  (hypatia-tile/emacs-flake#15). Until then, emacs-flake is changed only from
  a session in that checkout.
- **`agent-guard` knows the sibling checkouts through one table,** mapping
  each checkout to the sub-agent that may write into it. nix-packages is its
  first row, and emacs-flake's is added with its sub-agent.

ADR 0038 stays in force. This extends it to emacs-flake and to reviews.

## Consequences

- An Emacs bump can be followed from a session here from the moment
  emacs-flake opens its PR to the switch. A cache miss, which would put a
  twenty-minute Emacs build into the switch, is found at the nix-packages
  review instead.
- A nix-packages lock PR gets gates it has never had, in CI, where every
  reader can see them, instead of a local run only the reviewer saw. Until
  hypatia-tile/nix-packages#20 is done, a review here cannot supply them.
- The owner's checkouts are left alone: a review reads and builds from
  GitHub, so it works whatever branch either checkout is on.
- The skills here depend on the siblings' procedures as written there. A
  change to nix-packages' `lock-review` changes what the review here does,
  with no change here.
- Until hypatia-tile/emacs-flake#15 is done, nothing mechanical keeps a
  session here out of the emacs-flake checkout. The rule is written only.
- The `emacs-flake` sub-agent is specific to Claude Code, as the
  `nix-packages` one is. Once the guard knows that checkout, a Codex session
  here is refused writes into it and works from a session there.
