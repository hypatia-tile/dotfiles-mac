export default {
  extends: ['@commitlint/config-conventional'],

  // The weekly flake.lock commit is exempt, and the reason is that the rule it
  // breaks cannot be satisfied.
  //
  // .github/workflows/update-flake-lock.yml passes `commit-msg` to
  // `nix flake update --commit-lock-file --commit-lockfile-summary`, so only the
  // subject is ours: **Nix** writes the body, one line per changed input, and
  // each line is a single unbreakable token — a flake URI with its narHash,
  // 140-170 characters. `body-max-line-length` (100) therefore fails on every
  // one of these PRs (#147), and no wrapping can fix it: there is no space to
  // wrap at. The action has no input that shortens it either; the text comes
  // from Nix, not from the action.
  //
  // Scoped to messages whose *first* line is exactly the subject that workflow
  // sets, so nothing hand-written is covered — verified against a long body
  // line, a missing type, `chore(lock):` instead of `chore(deps):`, and the
  // subject appearing anywhere but line 1, all of which still fail. `ignores`
  // skips every rule for a matched message, which is acceptable here only
  // because the subject is the part this repository controls and pins.
  //
  // ADR 0011 already treats a lock commit as its own kind of commit, merged by
  // rebase so it survives verbatim; this is that decision reaching commitlint.
  //
  // If that workflow's `commit-msg` ever changes, this stops matching and the
  // next lock PR goes red — loudly, and in the one place that explains why.
  ignores: [(message) => /^chore\(deps\): update flake\.lock(\n|$)/.test(message)],
};
