# 0035. Capture ideas in an inbox issue, and start ADRs from an issue

- Status: Accepted
- Date: 2026-10-15

## Context

ADR 0019 moved deferred work to GitHub Issues. Since then an issue has become a
researched record. All 75 issues filed so far have bodies of at least 693
characters, with a median of 2,820, and none is under 400. Recording an idea
therefore means writing a small document. So the owner's ideas stay in their
head or in an external note, where this repository cannot see them (#227).

The roadmap issue cannot absorb them either. It orders the open issues and is
rebuilt by supersession, so adding one line means superseding it all. It
already carries four "Not filed" items (#226). Those items are ideas that never
became issues, placed in the roadmap because there was no other place for them.

ADRs have no consistent starting point. 21 of the 34 ADRs cite no issue. ADR
0034 began in a conversation and had no issue of its own. A decision that does
not come from an issue has no record of the problem before the solution was
chosen.

Two constraints shape the answer. An agent cannot edit or hide an issue comment:
`agent-guard` refuses `gh api` writes (ADR 0027). And issues here are rewritten
by supersession rather than edited, so their history stays visible.

## Decision

**One open inbox issue, one comment per idea.** Its title starts with
`Inbox (`, followed by the date it was opened. A comment has no title and no
label, so it can be added from a phone in one step.

- **English**, like every other artifact. Putting an idea into English is part
  of thinking it through, not a cost to remove.
- **The first line states what to do, in one sentence.** The rest is optional
  and free-form.
- **Either the owner or an agent writes it.** The owner writes directly. An
  agent writes after a short sparring session, when the owner asks.

**The inbox is superseded at triage, never edited.** A new inbox carries the
unprocessed entries in its body. The old one is closed with each entry's
outcome: promoted to an issue, done in a pull request, or dropped.

**The roadmap orders issues only.** Its "Not filed" items move to the first
inbox, and the roadmap points to the inbox in one line. Triage happens with
each roadmap rebuild, and whenever the owner asks.

**An ADR starts from an issue.** The issue records the problem before the
solution is chosen, and the ADR's Context cites it. `adr-new` asks for that
issue, and files one first when there is none. This adds a condition to the
step 5-3 check of ADR 0032 (#208): a new ADR fails unless it cites at least
one issue, as well as starting at `Status: Proposed`. Existing ADRs are not
edited, so the 21 without an issue stay as they are.

**The procedure is a project-scope skill, `inbox`.** It covers capture, triage
and the roadmap rebuild. It is not user scope, because every rule above is
this repository's own.

## Consequences

- Recording an idea is one English comment. The researched issue is written
  later, at triage, when the idea is promoted, or never.
- The inbox and the roadmap have separate jobs. The roadmap is what has been
  ordered; the inbox is what has not yet become anything. One idea no longer
  sits in both.
- Triage is a new recurring cost, paid at each roadmap rebuild. An inbox that
  is never triaged becomes another place where ideas wait without being seen.
  That is the risk this decision accepts.
- Every future ADR has an issue behind it, and the step 5-3 check enforces
  it. A decision made in conversation now takes one extra step: filing the
  issue first. This ADR follows that rule, starting from #227.
- The inbox is found by its title, not by pinning: `gh issue pin` is not in
  `agent-guard`'s allowlist. The owner may still pin it by hand.
