---
name: host-environment
description: Find out which repository owns a piece of this host's environment before inspecting or changing it — PATH, the login shell, globally installed tools, dotfiles under $HOME, keybindings, system settings — and route any change to that owner as a reviewed issue instead of editing it in place. Use before diagnosing or touching anything outside the current repository's working tree. Not for the repository's own devShell, dependencies or local config.
---

# Host environment

Parts of this host's environment are declared in repositories, and parts are
not yet. An agent working in some other repository must not change any of it
in place: a projected file is read-only and is overwritten on the next
projection, a hand-installed tool drifts from the declaration, and a
diagnosis that ignores how the host is built reaches the wrong conclusion.

## The boundary

- **In scope** — everything outside the current repository's working tree:
  `PATH`, the login shell and its startup files, globally installed tools,
  files under `$HOME` (`~/.config/*`, `~/.zshenv`, `~/.claude`, …), the global
  git config, keybindings, system settings, Homebrew, Nix profiles.
- **Out of scope** — the current repository's own files: its `flake.nix` and
  devShell, `.envrc`, lockfiles and package manifests, its `.git/config`.
  Change those as the task requires.
- **A tool is missing** — reach for a repository-local means first: add it to
  the devShell, or use `nix shell nixpkgs#<pkg>` / `nix run nixpkgs#<pkg>` for
  a one-off. Propose a global install only when the tool is genuinely needed
  outside this repository.

**If the current repository is itself an owner** — `hypatia-tile/dotfiles-mac`
or `hypatia-tile/nixos-config` — this skill has nothing to add: follow that
repository's own `AGENTS.md`.

## Never, from another repository

- Edit, `chmod`, replace or delete a file outside the working tree.
- Install globally: `brew install`, `nix profile install`, `npm -g`,
  `pip install --user`, `cargo install`, `go install`, `curl … | sh`.
- Run `defaults write`, `sudo`, `darwin-rebuild`, `nixos-rebuild`,
  `home-manager switch`, or the owners' `bin/project.sh`.

Reading and observing is always fine, and is the point of the next section.

## Who owns it — observe, do not assume

Ownership is decided per path or per tool, by looking. Never conclude it from
the operating system alone, and never from memory.

**Locate the owner repositories first.** Neither has a fixed path. Hints, to
be confirmed on the spot rather than trusted:

- `hypatia-tile/dotfiles-mac` — usually under `ghq` on every host:
  `ghq list -p hypatia-tile/dotfiles-mac`.
- `hypatia-tile/nixos-config` (private, NixOS hosts only) — last seen at
  `~/nixos-config`; `ghq list -p nixos-config` otherwise.

If one cannot be found, say so; do not guess where it would be.

**Then resolve the thing in question.** For a tool,
`readlink -f "$(command -v <tool>)"`; for a file, `ls -ld` and `readlink` on
it. Match the result against this table, top to bottom:

| Observation | Owner |
|---|---|
| The target is listed in `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-mac/projected` | dotfiles-mac — a payload placed by its `bin/project.sh`, declared in `modules/payloads.tsv` (on any host) |
| macOS, **and** the host is built from dotfiles-mac (below), **and** the thing comes from `/run/current-system`, `/etc/profiles/per-user/$USER`, a `/nix/store` symlink under `$HOME`, or `/opt/homebrew` | dotfiles-mac |
| NixOS, and the thing comes from `/run/current-system` or `/etc` | nixos-config |
| NixOS, and it is a `/nix/store` symlink under `$HOME` or comes from `~/.nix-profile` | **ambiguous** — Home Manager may be installed globally there without being declared in any repository |
| `/usr/bin`, `/bin`, `/usr/sbin`, `/System` | the operating system — nobody's to change |
| Anything else (`~/.nix-profile` on macOS, `/usr/local`, `~/.local/bin`, `~/.cargo/bin`, …) | **unknown** — likely an ad hoc install |

**Whether a macOS host is built from dotfiles-mac:** `darwin-rebuild` resolves
under `/run/current-system`, and the host's name (`scutil --get
LocalHostName`) is one of the flake's configurations:

```sh
nix eval --no-update-lock-file "$(ghq list -p hypatia-tile/dotfiles-mac)#darwinConfigurations" \
  --apply builtins.attrNames
```

If it is not, the second row does not apply and only the first does.

**Ambiguous or unknown: stop and ask.** Report what you observed — the
commands and their output — and ask the owner who owns it. Do not pick an
owner, and do not change it. NixOS ownership is not settled yet; expect this
case there.

**Diagnosis follows the owner.** Once the owner is known, read its
`AGENTS.md` and `docs/README.md` (dotfiles-mac) before explaining why
something behaves as it does — the layering is written down there, and a
general answer about how Nix, Home Manager or Homebrew usually work is often
wrong for this host.

## When a change is needed: an issue to the owner

The change belongs in the owner repository, made from a session there. From
here, the most you do is propose it as a GitHub issue, and only with the
owner's approval.

1. **Draft** the issue, without creating it. Write it in the owner
   repository's language (`github-language`; dotfiles-mac is English). Say
   what is needed, why, what you observed, and what you would change. Leave
   the origin out of the draft for now.
2. **Check the draft for secrets.** Run it through gitleaks, which need not be
   installed:

   ```sh
   nix run nixpkgs#gitleaks -- stdin --no-banner --redact -v < draft.md
   ```

   Exit 1 means it found something; `-v` names what. Then read it yourself for what gitleaks does not catch: absolute paths
   other than `$HOME`-relative ones, hostnames, internal URLs, the values of
   environment variables, tokens in pasted output.
3. **Ask the owner**, showing:
   - the full draft;
   - the result of both checks;
   - the choice of origin — name the current repository in an `Origin:` line,
     or leave it out. Offer both every time, whether the repository is public
     or private.

   This approval is where the owner decides whether to trust this repository
   and this proposal. Proceed only on an explicit yes; anything else means
   the issue is not filed.
4. **File it** with the `from-agent` label, as approved and nothing more:

   ```sh
   gh issue create -R hypatia-tile/<owner> --label from-agent \
     --title "<title>" --body-file draft.md
   ```

   For an **ambiguous** or **unknown** owner, the owner names the repository
   in step 3; there is no default.

Then carry on with the task in the current repository without the change, or
stop if it cannot proceed — and say which.
