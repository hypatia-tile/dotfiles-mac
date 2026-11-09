---
name: weekly-locks
description: The weekly round of lock PRs across hypatia-tile/emacs-flake (Fridays), hypatia-tile/nix-packages (Saturdays) and this repository (Sundays) — find where the chain stands, say which PR was opened before the one upstream of it merged and needs its workflow run again, then review each open PR in chain order with sibling-lock-review and lock-review, handing every merge, run approval and re-run to the owner. Use when the owner asks for the weekly tasks or the weekly lock round, on any day of the week. The owner may phrase this in Japanese ("週次タスク", "週次のlock").
---

# weekly-locks

Three scheduled workflows bump a lock each week, a day apart, at 06:00 JST
(ADR 0039):

| Day | Repository | Workflow | Review |
|---|---|---|---|
| Friday | hypatia-tile/emacs-flake | `update.yml` | `sibling-lock-review` |
| Saturday | hypatia-tile/nix-packages | `update-flake-lock.yml` | `sibling-lock-review` |
| Sunday | this repository | `update-flake-lock.yml` | `lock-review` |

Each one takes the `main` of the one before it. A PR opened before the one
upstream of it merged does not carry it. This skill finds where the round
stands, whatever the day, and runs the reviews in order. It restates neither
review: it decides which to run, and on what.

## Steps

1. **Take stock.** For each repository, in chain order:
   - the open lock PR, its number and head:

     ```sh
     gh pr list -R <repo> --state open --search '"update flake.lock" in:title' \
       --json number,title,headRefOid,createdAt \
       -q '.[] | select(.title == "chore(deps): update flake.lock")'
     ```

     The search is quoted and filtered because GitHub's search drops the
     `chore(deps):` punctuation and matches nothing with it;
   - the latest scheduled run, and its conclusion:
     `gh run list -R <repo> --workflow <workflow> --limit 1 --json conclusion,createdAt,url`.

   A red run with no PR is a finding, not a quiet week. emacs-flake's
   `update.yml` opens no PR when the patch stops applying
   (hypatia-tile/emacs-flake#2). No PR after a green run means the lock was
   already current.
2. **Check each later PR against the one before it.** Read which revision
   the later PR's lock takes of the earlier repository, and compare it with
   that repository's `main`:

   ```sh
   nix flake metadata --json github:<later repo>/<head> \
     | jq -r '.locks.nodes as $n | $n[$n.root.inputs["<input>"]].locked.rev'
   gh api repos/<earlier repo>/commits/main -q .sha
   ```

   The input is `emacs-flake` in nix-packages and `nix-packages` here.
   - **Equal, and the earlier PR is merged or there is none:** the later PR
     carries everything merged upstream.
   - **The earlier PR is still open,** equal or not: review the earlier one
     first. Its merge moves the earlier `main`, so the later PR is re-run
     after it and reviewed only then. A review before that is wasted
     (2026-11-08: #345 matched nix-packages' `main` until #19 merged).
   - **Different, and the earlier PR is merged:** the later PR is stale.
     Hand the owner the re-run, which updates the same PR in place:
     `! gh workflow run <workflow> -R <later repo>`. Review it after the new
     run, not before.

   A nix-packages PR one emacs-flake revision behind costs little: an
   emacs-flake lock bump alone changes nothing on this host (ADR 0039). It
   matters when emacs-flake's `main` changed more than `flake.lock`. This
   repository's PR one nix-packages revision behind always matters.
3. **Review the open PRs in chain order,** each with its own skill:
   emacs-flake's and nix-packages' with `sibling-lock-review`, this
   repository's with `lock-review`. Stop at the first PR to hold, and say
   which later PRs wait on it.
4. **Hand over in chain order.** A merge upstream is followed by the re-run
   of the PR after it, from step 2, before that PR is merged. This
   repository's merge is followed by the switch, which is the owner's, and
   `lock-review`'s post-switch check.

## Report

Open with a table of the three repositories: the PR (or "none", with the run's
conclusion), its head, whether it carries the `main` upstream of it, and the
review's verdict. Then each review's own report, and the owner's `! gh …`
steps in the order they are to run.

## Rules

- Never merge, approve a run, re-run a workflow, push or switch. Hand each to
  the owner.
- Never write into the emacs-flake or nix-packages checkout
  (`sibling-lock-review`).
- Never run `nix flake update`. A stale PR is re-run by its workflow, never
  refreshed by hand.
