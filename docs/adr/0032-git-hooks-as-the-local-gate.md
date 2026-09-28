# 0032. Run the verification gates as Git hooks, from checks shared with CI

- Status: Proposed
- Date: 2026-09-28

## Context

`preflight` is the standing local gate for every change (ADR 0019, ADR 0022).
It is a skill: eight steps of prose that an agent reads and carries out. That
shape has three failure modes, and all three have happened or are open:

- **Skipped or misscoped steps.** Which steps run is decided by the agent
  reading the skill's *Scope shortcuts* section. Nothing mechanical checks the
  reading.
- **Drift from CI.** Every gate is written twice, once in
  `.github/workflows/ci.yml` and once in the skill. #112 caught the skill
  restating CI's build filter wrongly. #89 and #91 were gates that the file
  they check could not trigger.
- **Not run at all.** Nothing stands between an unchecked tree and a commit or
  a push. The repository has no Git hooks: `.git/hooks` holds only samples and
  `core.hooksPath` is unset.

The two sides also run different tools. CI calls most linters through
third-party Actions that pin their own versions
(`markdownlint-cli2-action@v19`, `action-shellcheck`, `gitleaks-action`,
`stylua-action`, `commitlint-github-action`). `preflight` calls
`nix run nixpkgs#…`, which resolves through the global flake registry, that is,
the current head of nixpkgs-unstable and not `flake.lock`. The local version
floats, and the skill carries a standing exception for the false positives
that causes (MD060). The flake has no `devShells`, `apps` or `checks` output.

`config/nvim/bin/check` already shows the shape that avoids the drift: the
payload owns an executable check and CI calls it. #82 names it as the model.
The agent pre-tool-use hook of ADR 0027 shows the other half: a rule stated as
code and enforced for every agent. Git hooks, however, can be bypassed without
a trace (`git commit --no-verify`, `LEFTHOOK=0`,
`git -c core.hooksPath=…`), and an agent that fails a check will reach for
exactly that.

Some rules that `AGENTS.md` states only in prose are also mechanically
decidable, and the history shows where their real boundaries lie:

- ADR 0011 keeps `flake.lock` in dedicated commits. But `0a3d9c0` correctly
  moved it together with `flake.nix`, because adding an input has to lock it.
  The rule that the history actually follows is narrower: **an existing
  input's `locked` entry never moves outside a dedicated commit.**
- Every edit to an existing ADR in the history is a change to its `Status`
  line, made by the owner (`accept 0031`, `accept 0029`, …). Everything else
  arrived as a new file starting at `Status: Proposed`.
- Work happens on feature branches off `main`, and the `main` ruleset refuses
  direct pushes (ADR 0012). A commit made on `main` locally is only discovered
  at push time.

## Decision

**Each gate is an executable check script, and the script is the single source
of truth for it.** A check lives beside the thing it checks: `bin/check-*.sh`
for repository-wide gates, `config/<part>/bin/check` for a payload that owns
its verification, as `config/nvim/bin/check` already does. Local hooks, CI and
`preflight` all call the same scripts. No gate's command is written a second
time in `ci.yml`, in `lefthook.yml` or in a skill.

**A check owns its scope.** Each script accepts the changed files as arguments.
If none of them is its concern, it exits 0 having done nothing. With no
arguments it checks everything. It can also be asked whether a set of files
concerns it, without running. The patterns that decide this live in the script
and nowhere else:

- Lefthook passes `{staged_files}` or `{push_files}` and declares no `glob`.
- CI's `changes` job stops using `dorny/paths-filter`. It computes
  `git diff --name-only` against the base and asks the scripts, then derives
  the job-gating outputs (`build`, `zsh`, `nvim`) from the answers.

ADR 0022's principle, that the check which runs is the one that can fail for
the thing that moved, is unchanged. What changes is where the mapping is
written. Job names stay as they are, so the required status checks of ADR
0012's ruleset are unaffected.

**Tool versions are pinned by the flake.** A check-oriented `devShell` is added
to `flake.nix`. It is built from the locked nixpkgs and carries Lefthook and
every tool the checks use. It is exported for `aarch64-darwin` and for the
Linux system the Ubuntu runners use. Scripts assume their tools are on `PATH`.
CI runs them as `nix develop .#<shell> -c <script>` in place of the linter
Actions. Linter versions then move only when `flake.lock` moves, in the
dedicated commits of ADR 0011, and a new lint finding surfaces in that pull
request. The devShell is not part of any system closure, so it does not show
up in `preflight`'s closure diff.

**Lefthook is the dispatcher, and it is invoked through tracked stubs.** A
tracked `.githooks/` directory holds one stub per hook, each a single line:
`exec nix develop .#<shell> -c lefthook run <hook> "$@"`. Installation is one
command run by the owner, `git config core.hooksPath .githooks`. It is recorded
in the `manual-setup` skill. `lefthook install` is not used, and nothing
installs hooks as a side effect of entering a shell. A missing `nix` makes the
hook fail rather than pass, and the hook does not depend on `PATH` or direnv.

**Stages are assigned by cost and by whether the result is decidable:**

| Stage | Runs |
| --- | --- |
| `pre-commit` | the fast checks, on staged files: nixfmt, statix, deadnix, markdownlint, shellcheck, the stray-tag scan, `project.sh --validate`, `check-skills.sh`, `check-agent-guard.sh`, the nvim hook-path check, `zsh -n`, `check-abbr.sh --commands`, stylua, gitleaks on the staged diff |
| `commit-msg` | commitlint |
| `pre-push` | the slow checks, on the pushed range: `nix flake check`, the closure build, `config/nvim/bin/check`, the LuaLS typecheck |
| `preflight` only | the closure diff and the collision check, which need a reader's judgement and cannot be pass or fail |

**`preflight` becomes the fallback and the review step.** It verifies that
`core.hooksPath` is `.githooks`, runs every hook stage over the whole tree,
and then performs the two judgement steps. It stops restating commands: a step
that names a command someone would copy has become a check script instead.

**The agent guard refuses hook bypasses.** `bin/agent-guard.sh` gains denials
for:

- `git commit --no-verify` and `-n`, and `git push --no-verify`;
- setting `LEFTHOOK`, `LEFTHOOK_EXCLUDE`, or any other variable the pinned
  Lefthook reads to skip work, as established from its documentation;
- any change to `core.hooksPath`, including `git -c core.hooksPath=…`;
- writes into `.git/hooks` or `.githooks`.

`bin/check-agent-guard.sh` gains a case for each of these. An agent whose check
fails reports the failure. The owner keeps `--no-verify` as the escape hatch,
since the guard does not apply to the owner's own terminal. Feedback that runs
while the agent is still working (a post-edit hook, or an end-of-turn hook) is
out of scope. The three agents' hook events differ and have not been measured,
so it is left for an issue.

**Three prose rules become checks**, each in its own branch after the base
lands:

- **Locked inputs do not ride along (ADR 0011).** A commit that changes
  `flake.lock` together with anything else fails if the `locked` entry of any
  node present on both sides differs. Adding or removing a node is allowed.
- **Commits are not made on `main`.** `pre-commit` refuses when `HEAD` is
  `main`.
- **ADRs are append-only apart from their status.** An edit to an existing
  `docs/adr/NNNN-*.md` fails unless the only changed line is `- Status:`. A
  new ADR fails unless it starts at `Status: Proposed`.

A check for English-only artifacts was considered and rejected. Six tracked
files legitimately contain Japanese, and an allowlist would cost more to keep
than the check would save.

**Rollout is incremental, one concern per branch.** In order:

1. the devShell;
2. the check scripts and the CI changes that call them, including the `changes`
   job;
3. the stubs, `lefthook.yml` and the guard's denials;
4. the reduced `preflight`;
5. the three rule checks.

Each step leaves CI and `preflight` working on their own. Rollout pauses if
either measurement below does not hold.

**Measured before it is relied on:**

- *TBD*: the wall-clock cost of `nix develop` per hook invocation with a warm
  evaluation cache.
- *TBD*: that a stub fails closed when `nix` or the devShell is unavailable,
  including inside each agent's sandbox, where a commit the owner instructed
  must still be able to run the hook.

This amends ADR 0012's CI: the lint jobs call repository scripts instead of
third-party Actions, and job names and required checks are unchanged. It
amends ADR 0022's paths filter, whose mapping moves from `ci.yml` into the
check scripts, and leaves its principle unchanged. It extends ADR 0027's guard
with hook-bypass denials. It gives ADR 0011 and the ADR workflow of ADR 0007 a
mechanical check that matches their practice. `preflight` stays a skill, as
ADR 0019 requires.

## Consequences

- A gate is written once. Changing what a check does, or which files trigger
  it, is one edit, and the pull request that makes it shows the command and its
  scope side by side. This is #82's requirement that verification double as
  its own description.
- Local and CI run identical tool versions, and the MD060 exception in
  `preflight` goes away with the version skew that caused it. The linter
  versions become part of what a `flake.lock` pull request moves, and
  `lock-review` has to expect new lint findings there as a legitimate outcome.
- The `changes` job becomes repository shell instead of an off-the-shelf
  Action. It is the most consequential script in CI: a bug there skips a gate
  silently, and its failure mode must be to run the job, not to skip it.
- Every commit pays the `pre-commit` cost, and every push pays for a closure
  build. The build is incremental against the local store and is long only when
  the lock moves. The owner pays this, since the owner pushes.
- Lefthook is replaceable. It holds only which stage calls which script, so
  removing it means rewriting the stubs, and no check is lost (#81).
- The guard's new denials can refuse something legitimate, such as an agent
  running an owner-instructed `git commit -n` for a WIP commit. That is
  intended: skipping the hooks is the owner's decision.
- Hooks are only as strong as their installation. A fresh clone runs none until
  `core.hooksPath` is set, which is why `manual-setup` records the step and
  `preflight` verifies it instead of assuming it.
- The ADR check encodes the owner's own practice as a gate. A future need to
  correct an existing ADR beyond its status, for example a broken link, runs
  into it, and would have to go through a superseding ADR, as `AGENTS.md`
  already requires, or through the owner's `--no-verify`.
