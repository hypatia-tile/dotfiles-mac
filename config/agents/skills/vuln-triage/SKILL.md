---
name: vuln-triage
description: Check the tools a repository and this host use for known vulnerabilities, and settle every blocking finding with the owner — fix now or defer with a reason — before any other work. Use at the start of every session in a repository, when a SessionStart hook reports vulns findings, or when the owner asks about vulnerable versions or security patches (the owner may ask in Japanese, e.g. "脆弱性を確認して", "パッチを当てたい").
---

# Vulnerabilities first

A vulnerable tool keeps working, so nothing in a normal session says it is
there. This skill makes the check the first thing a session does, and keeps
the decision about each finding with the owner: some fixes are risky in the
middle of other work, and some findings do not matter for a repository nobody
runs.

## 1. Get the findings

If the session opened with a `vulns` hook message, use it. Otherwise run, from
the repository root:

```sh
vulns repo .
vulns host
```

`vulns --help` explains the columns. Exit status 1 means something blocks;
the hook message lists only the blocking lines.

**Without `vulns` on `PATH`** (a host that does not have it), say so, then
check the lockfiles with
`nix run nixpkgs#osv-scanner -- scan source --lockfile <file>` for each
lockfile, passed one by one. Runtimes then go unchecked; say that too.

## 2. Show the blocking findings before the request

Before acting on the owner's request, list every finding at level `block`: the
name, the version in use, the fixed version, the severity, the advisory ID and
where it comes from. Add one line for the findings below the threshold and the
deferred ones. Do not start the requested work yet.

Then propose a fix for each blocking finding, as its own branch in this
repository. The fix depends on the kind:

| Finding | Fix |
|---|---|
| Package, with a fixed version | Move it to that version with the repository's own package manager. For a transitive package, the manager's override mechanism. |
| Package, no fixed version | Nothing to update to. Say what the advisory recommends, and propose a deferral. |
| Runtime, `nixpkgs-unstable has …` | Move the repository's nixpkgs pin, following that repository's own rules for its lock file. |
| Runtime, `patched upstream, not in nixpkgs-unstable yet` | Wait, by default: propose a deferral of 7 days citing the upstream fix. An overlay that builds the patched version only if the owner calls for it, for a Critical finding or one known to be exploited. |
| Runtime, end-of-life | Move to a supported line. That is a real change, so propose it as its own piece of work. |
| Runtime from `.nvmrc` or `.tool-versions` | Raise the version in that file. |

Read the advisory before recommending a risky fix. A major-version jump, or a
change in the middle of the owner's open work, is a reason to say so.

## 3. Wait for the owner's decision

Each blocking finding is either:

- **fixed now**: the fix goes first, on its own branch, before the owner's
  request; or
- **deferred, with a reason and an expiry**: 30 days by default, 7 for
  "waiting for the channel".

The owner decides. Project work starts after every blocking finding has one
of the two.

### Where a deferral goes

It depends on who owns the repository, because a deferral in your own
repository is a decision that belongs in its history.

- **The owner's repository:**
  - packages go in `osv-scanner.toml` at the repository root, as
    `[[IgnoredVulns]]` with `id`, `ignoreUntil` and `reason`;
  - runtimes go in `.vulns-defer`, with one `<name>@<version>`, a tab,
    `<YYYY-MM-DD>`, a tab, and the reason per line.

  Both are committed according to that repository's own rules on who commits.
- **Any other clone:** the same two files under
  `~/.local/state/vulns/<path>/`, where `<path>` is the repository's absolute
  path without its leading `/` and with every `/` as `%`. Name the runtime file
  `vulns-defer`. Nothing is written inside the clone.

A deferral names one version. When the version changes, the finding comes
back, and that is intended.

## 4. Host findings: one tracked issue per tool

A `vulns host` finding belongs to the repository that declares the host's
tools, not to the current one. Find it with the `host-environment` skill. So
does a finding in that repository's own devShells. A project's own findings
stay in that project (step 3).

**Deferred host findings need nothing here.** `vulns host` reads the owner
repository's `.vulns-defer` from anywhere, so a decided finding shows as
`deferred` with its issue number and does not block.

For each **blocking** host finding, the owner repository may track it with
one issue per tool, under a `vulnerability` label and from its template
`.github/ISSUE_TEMPLATE/vulnerability.md`. `hypatia-tile/dotfiles-mac` does.
Look for an open one by the tool's name:

```sh
gh issue list -R <owner> --label vulnerability --state open --search "<tool> in:title"
```

- **Found:** say "tracked in #N". If the version in use differs from the
  issue's, offer a comment on it saying so. Do not open a second issue.
- **Not found:** file one from the template. Fetch it, and fill every
  section; an empty one is an omission, and "none" is an answer:

  ```sh
  gh api repos/<owner>/contents/.github/ISSUE_TEMPLATE/vulnerability.md \
    -H 'Accept: application/vnd.github.raw'
  ```

  Use the template's title format, and drop its front matter and comments
  from the body.
  - **In the owner repository:** file it with the `vulnerability` label,
    after the owner has seen it.
  - **Anywhere else:** through `host-environment`'s procedure for an issue to
    the owner. That means the gitleaks check, the owner's approval, and the
    choice of naming the originating repository. Label it `vulnerability` as
    well as `from-agent`. Never fix the finding in place.

Once it is filed or found open, it counts as handled for this session.

## 5. What may be written in public

Deferral reasons, commit messages and issues are often public. Check the
repository's visibility (`gh repo view --json visibility`) before writing one.

**Public is fine for a publicly disclosed advisory about a tool**: its ID,
the version in use, the fixed version, why the fix waits, and which tools
use the vulnerable version. That adds little an outsider could not already
read: the advisory is published, and in a repository with public lock files
the versions can be derived from them. Recording it in an issue is what lets
other repositories, and later sessions, find the decision without relying on
any agent's memory.

**Never public:**

- a vulnerability that has not been publicly disclosed;
- a finding in a private repository's own code;
- anything about what a machine exposes to a network: listening services,
  ports, hostnames, addresses.

For these, ask the owner where the record goes: a private repository, or
the repository's private security advisories for a flaw in its own code. Do
not post first and ask afterwards; a public post cannot be taken back.

## When it is done

Every blocking finding is fixed, deferred, or, for a host finding, tracked
in an issue. Say
so in one line, then turn to the owner's request.
