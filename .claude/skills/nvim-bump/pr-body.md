<!--
PR body template for an nvim-config pin bump (ADR 0014).
Filled and printed by `bin/nvim-bump-check.sh --emit-pr-body`; do not open
this file expecting rendered output. Placeholders (substituted by the script):
  {{OLD_REV}} {{NEW_REV}}   short old/new nvim-config revisions
  {{PR_RANGE}}              e.g. "#11–#14" (derived from the clone log)
  {{CHANGE_BULLETS}}        one bullet per landed nvim-config PR
  {{HOST}}                  darwinConfigurations host that was built
  {{NVIM_STORE_PATH}}       store path .config/nvim now resolves to
  {{VERIFIED}}              extra --assert-absent/--assert-present result lines
-->
## Summary

Bump the pinned `nvim-config` input (ADR 0014) from `{{OLD_REV}}` to
`{{NEW_REV}}`, pulling in nvim-config {{PR_RANGE}}:

{{CHANGE_BULLETS}}

Pin-only bump per ADR 0011: the commit touches `flake.lock` and only the
`nvim-config` node. No other tree changes.

## Verification

`bin/nvim-bump-check.sh` green on host `{{HOST}}`:

- `darwin-rebuild build --flake .#{{HOST}} --no-update-lock-file` builds clean
  (build-only; no switch).
- Built `.config/nvim` resolves to the new pin (`{{NVIM_STORE_PATH}}`).
{{VERIFIED}}
- `flake.lock` diff confined to the `nvim-config` node
  (`{{OLD_REV}}` → `{{NEW_REV}}`).

## Owner attention — post-merge

Apply with `sudo darwin-rebuild switch --flake .#{{HOST}}`, then in live nvim
confirm:

- no startup errors; `:echo stdpath('config')` resolves through
  `~/.config/nvim` to the new store path;
- `:Lazy` clean against the shipped `lazy-lock.json`;
- the behavior change that motivated the bump is observable.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
