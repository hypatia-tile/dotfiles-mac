# 0022. Verification matched to the change, and switching before the PR

- Status: Accepted
- Date: 2026-09-05

Promoted to Accepted by shinokun, 2026-09-05.

## Context

ADR 0012 defined CI as four job groups, with a paths filter deciding whether
the macOS closure build runs. That filter includes `config/**`, so editing one
line of zsh triggers a 3–4 minute macOS build.

That build proves almost nothing about a zsh file. It copies the file into the
store; it does not parse it. `zsh -n` does, in well under a second — checked
against all nine zsh payloads, which pass, and against a deliberately broken
file, which it rejects. Nor does anything else cover them: ADR 0012's
shellcheck job explicitly excludes `config/`, because shellcheck does not
support zsh (SC1071).

The mismatch also cannot be fixed by making the job cheaper. A config-only
rebuild takes 8.18 seconds locally, so nearly all of those 3–4 minutes is fixed
overhead — installing Nix, restoring the cache. The lever is whether the job
runs at all, not how fast it is.

ADR 0021 sharpens this to the point of proof: once payloads are
placed as working-tree symlinks, a content edit does not change the closure at
all, because the link target is a path string. CI would rebuild an identical
closure. The same fact removes `preflight`'s grip: its closure diff — the step
that proves a change is what it claims to be — becomes blind to configuration
changes, which are the most frequently edited files in the repository.

Separately, `docs/operations.md` §1 documents the change loop as branch →
preflight → PR → merge → switch, and that ordering is felt as a rule: nothing
can be tried on the machine until it has been through CI and a pull request.
It is worth being precise about what it is. **No ADR prohibits the owner from
switching earlier.** ADR 0003's build-only rule was migration-era and was
discharged by the ADR 0015 cutover. What ADR 0018 retained is that *Claude*
never switches and that applying is the owner's manual step — a statement about
who, not about when. The ordering is documentation, not a decision.

The safety net that would make an earlier switch survivable already exists and
does not depend on the change being committed: 111 system generations, and
`sudo darwin-rebuild switch --rollback` documented in `docs/rollback.md`.

Diagnosis and alternatives are in issue #64.

## Decision

**CI runs the test that matches what changed** — not lighter tests for smaller
changes, but the test that can actually fail for the thing that moved.

| Changed | Test |
|---|---|
| zsh payloads | `zsh -n` over each file |
| Neovim payload | `stylua --check` and the headless startup check, moved here from `nvim-config`'s CI with a paths filter |
| `*.nix`, `flake.lock`, workflow files | the macOS closure build, unchanged |

`config/**` leaves the closure-affecting paths filter. As with the existing
docs-only path, the macOS job reports as *skipping* rather than being absent,
so it still satisfies the required status check and ADR 0012's `main` ruleset
is unaffected. Pushes to `main` continue to build unconditionally, keeping the
cache warm.

The Neovim startup check stays heavy — it installs Neovim and Deno and restores
plugins to match `lazy-lock.json`. That is consistent with the principle rather
than an exception to it: it is heavy because it is the *right* test for that
payload, not because the change is large.

**Not every payload gets a validator.** `zsh -n` and `stylua` exist; there is
no comparably cheap check for the tmux, kitty, alacritty, aerospace, lazygit or
git payloads, and inventing one is not worth it. Those are covered by the
second half of this decision: the change is already running on the machine
before the pull request exists.

**`preflight` gains the same content checks**, and its closure-diff step is
re-read rather than dropped. After ADR 0021 the expected result for a
config-only change is that the closure does **not** move — so a closure that
moves on a config-only change is itself the finding, and the step keeps its
value inverted.

**An experimental switch may precede the pull request.** The owner may switch
from a feature branch, including from a dirty working tree. Requiring a commit
per iteration would break the loop this exists to enable, and the generation
rollback that makes switching survivable does not depend on commits.

The invariant is about the resting state, not the iteration: **once a change is
merged, the machine is switched from `main`.** Drift from that is mechanically
detectable, and a check is added to `bin/` and named by the `ship-pr` skill as
its post-merge step:

```sh
nix build "git+file://$PWD?ref=refs/heads/main#darwinConfigurations.Kazukis-MacBook-Air.system" \
  --no-link --print-out-paths --no-update-lock-file
readlink /run/current-system
```

Equal means the machine is running `main`; it takes 6.6 seconds. This does not
belong in `preflight`, which runs when being on a branch is expected and where
the check would fire on every ordinary run.

`docs/operations.md` §1 is rewritten around this, and `docs/rollback.md`'s
instruction to record the generation before switching applies to experimental
switches too — more so, since they are more frequent.

**The retained guardrails are untouched.** Claude still never runs
`darwin-rebuild switch`, any activation script, or `sudo`; the
`.claude/settings.json` deny rules stay exactly as they are. This decision
changes when *the owner* may switch, and nothing about what an agent may do.

This amends ADR 0012's job-group definition and paths filter. It depends on
ADR 0021 for the claim that config content no longer affects the closure; the
CI half is implementable without it, but the argument is weaker, since today
the macOS build at least rebuilds a genuinely different closure.

## Consequences

A configuration change is verified by something that can fail for the right
reason, in seconds rather than minutes, and the machine stops being the last
place a change is tried rather than the first. Trying and shipping become
independent: the pull request documents and reviews a change that has already
been living on the machine.

That is also the trade. **The machine can be running something that is on no
branch anyone else can see** — uncommitted, unpushed, unreviewed. The
resting-state invariant and its check are what keep that from becoming
permanent, and they are only as good as the habit of running them; the check
being 6.6 seconds is the argument that the habit is affordable.

**Coverage narrows honestly.** Payloads without a validator are gated by the
owner having run them, which is weaker than a test and stronger than the
closure build it replaces — that build never established anything about their
content either. What changes is that this is now stated rather than implied.

**A mixed state becomes possible in a new way.** With ADR 0021, a machine
switched from a branch runs that branch's closure with the working tree's
configuration; after a rollback it runs an older closure with the current
configuration. Neither is new in kind, but both become ordinary rather than
exceptional, which is why `docs/rollback.md` must name them.

CI gets cheaper in the common case and no cheaper in the rare one. The macOS
runner is used for changes that can actually move the closure, which is what
ADR 0012 intended before `config/**` was in the filter.
