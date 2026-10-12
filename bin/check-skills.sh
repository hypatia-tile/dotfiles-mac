#!/usr/bin/env bash
# Validate this repository's skill trees.
#
# The failures caught here are the silent kind. A skill with no description is
# never surfaced to the model, and a `name` that disagrees with its directory
# is invoked under one spelling and stored under another. Neither produces an
# error at run time — the skill is simply never used, and nothing says so.
# Codex adds its own silent case: its loader ignores a skill whose fields it
# rejects, and its skill-creator allows only lowercase letters, digits and
# hyphens, under 64 characters.
#
# Two trees, since ADR 0028:
#   .claude/skills        project scope — this repository's own procedures
#   config/agents/skills  user scope — linked into ~/.claude/skills and
#                         ~/.codex/skills by Home Manager (ADR 0034)
#
# and one mirror of the first, .codex/skills, because Codex does not read
# .claude/skills. Measured on codex-cli 0.154.0 through the app server's
# `skills/list`: a repository's skills are read from .codex/skills and
# .agents/skills, both reported at scope "repo", and .claude/skills is not
# among the roots. The canonical tree stays .claude/skills (ADR 0019), so each
# project skill is mirrored as a relative symlink — git stores one link
# (mode 120000), not a second copy, and Codex resolves it to the canonical
# SKILL.md.
#
# Beyond each skill's own frontmatter, four checks exist only because the
# trees are wired into something else:
#   - tracked: project skills are tracked through a `.gitignore` allowlist
#     (`.claude/skills/*` ignored, one `!.claude/skills/<name>` per skill), so a
#     skill nobody allowlists works here and is absent from every clone, with
#     `git status` clean throughout. CLAUDE.md names the trap.
#   - declared: a user skill needs its name in the `skills` list of
#     modules/home/payloads/shared.nix; without it, no agent sees it.
#   - unique across trees: a name in both is ambiguous in a session that sees
#     both scopes.
#   - mirrored: a project skill with no .codex/skills link reaches Claude Code
#     and no other agent, and nothing says so.
#
# The validator was ported from hypatia-tile/skills (MIT, same owner) and
# copied rather than consumed as a flake input: an input would gate every fix
# behind a lock bump (ADR 0011).
#
# Usage: bin/check-skills.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh; any in-scope FILE validates
#        both trees and their wiring in full)
# Exit:  0 sound; 1 a skill is broken, untracked, undeclared, duplicated or
#        unmirrored
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

PAYLOAD_MODULE=modules/home/payloads/shared.nix

scope '.claude/skills/*' '.codex/skills/*' 'config/agents/skills/*' \
  "$PAYLOAD_MODULE" .gitignore
check_gate "$@"

PROJECT_ROOT=.claude/skills
USER_ROOT=config/agents/skills
# Inside the checkout, not $HOME. The `.codex/skills/<name>` links that
# $PAYLOAD_MODULE places are a different thing entirely — those are user-scope
# skills placed under $HOME by Home Manager.
CODEX_MIRROR=.codex/skills

fail=0
total=0
err() { echo "error: $*" >&2; fail=1; }

in_git=false
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && in_git=true

# check_tree <dir>: every skill directory's own validity. Leaves the names it
# found in $names. Called directly, never in $(...): a subshell would discard
# the failures it records, which an earlier draft did — printing errors and
# exiting 0.
names=""
check_tree() {
  local root=$1 dir slug file frontmatter name description tracked found=0
  names=""
  if [[ ! -d $root ]]; then
    err "$root is not a directory"
    return
  fi
  # Consulted whenever there is an index at all. An earlier version skipped the
  # check when nothing under the root was tracked yet — exactly the state of a
  # new tree, which it then passed without looking.
  tracked=""
  $in_git && tracked="$(git ls-files -- "$root")"
  $in_git || echo "note: not a git work tree, skipping the tracked check for $root" >&2

  shopt -s nullglob
  for dir in "$root"/*/; do
    found=$((found + 1))
    slug="$(basename "$dir")"
    file="$dir/SKILL.md"
    names+="$slug"$'\n'

    if [[ ! -f $file ]]; then
      err "$root/$slug: SKILL.md is missing"
      continue
    fi

    if $in_git && ! printf '%s\n' "$tracked" | grep -qxF "$root/$slug/SKILL.md"; then
      if [[ $root == "$PROJECT_ROOT" ]]; then
        err "$root/$slug: not tracked — add '!$root/$slug' to .gitignore"
      else
        err "$root/$slug: not tracked — git add it"
      fi
    fi

    if [[ "$(head -n 1 "$file")" != "---" ]]; then
      err "$root/$slug/SKILL.md: does not open with YAML frontmatter"
      continue
    fi

    frontmatter="$(awk 'NR == 1 { next } /^---[[:space:]]*$/ { exit } { print }' "$file")"
    name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
    description="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

    # No duplicate check within a tree: requiring `name` to equal the directory
    # makes uniqueness a property of the filesystem. Across trees it is not.
    if [[ -z $name ]]; then
      err "$root/$slug/SKILL.md: frontmatter has no 'name'"
    elif [[ $name != "$slug" ]]; then
      err "$root/$slug/SKILL.md: name '$name' does not match its directory"
    fi
    if ! [[ $slug =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || ((${#slug} >= 64)); then
      err "$root/$slug: name must be lowercase letters, digits and single hyphens, under 64 characters (Codex)"
    fi

    if [[ -z $description ]]; then
      err "$root/$slug/SKILL.md: frontmatter has no 'description'"
    fi
  done

  [[ $found -gt 0 ]] || err "no skills found under $root"
  total=$((total + found))
}

check_tree "$PROJECT_ROOT"
project_names=$names
check_tree "$USER_ROOT"
user_names=$names

while IFS= read -r n; do
  [[ -n $n ]] || continue
  if printf '%s\n' "$project_names" | grep -qxF "$n"; then
    err "'$n' is both a project skill ($PROJECT_ROOT) and a user skill ($USER_ROOT)"
  fi
done <<< "$user_names"

# Declared: every user skill is in the `skills` list of the shared payload
# module, which links each name into both agents, and every name in that list
# is a skill. A listed name with no directory is not an evaluation error:
# mkOutOfStoreSymlink takes a path string, so the link would simply dangle.
declared=$(awk '/^[[:space:]]*skills = \[/,/\];/' "$PAYLOAD_MODULE" | grep -oE '"[^"]+"' | tr -d '"' || true)
[[ -n $declared ]] || err "$PAYLOAD_MODULE: no \`skills = [ ... ];\` list found"
while IFS= read -r n; do
  [[ -n $n ]] || continue
  printf '%s\n' "$declared" | grep -qxF "$n" ||
    err "$USER_ROOT/$n: not in the skills list of $PAYLOAD_MODULE, so no agent sees it"
done <<< "$user_names"
while IFS= read -r n; do
  [[ -n $n ]] || continue
  printf '%s\n' "$user_names" | grep -qxF "$n" ||
    err "$PAYLOAD_MODULE: skills lists '$n', which is not a directory under $USER_ROOT"
done <<< "$declared"

# Mirrored: one relative symlink per project skill, tracked, pointing at the
# skill of the same name — and nothing else under the mirror, so a skill an
# agent drops there is reported rather than read as a project procedure.
while IFS= read -r n; do
  [[ -n $n ]] || continue
  link=$CODEX_MIRROR/$n
  if [[ ! -L $link ]]; then
    if [[ -e $link ]]; then
      err "$link: not a symlink — the skill itself belongs in $PROJECT_ROOT/$n, linked from here"
    else
      err "$link: missing — Codex does not read $PROJECT_ROOT; ln -s ../../$PROJECT_ROOT/$n $link"
    fi
    continue
  fi
  if [[ "$(readlink "$link")" != "../../$PROJECT_ROOT/$n" ]]; then
    err "$link: points at '$(readlink "$link")', not '../../$PROJECT_ROOT/$n'"
  fi
  if $in_git && ! git ls-files --error-unmatch "$link" >/dev/null 2>&1; then
    err "$link: not tracked — git add it"
  fi
done <<< "$project_names"

shopt -s nullglob
for link in "$CODEX_MIRROR"/*; do
  n="$(basename "$link")"
  printf '%s\n' "$project_names" | grep -qxF "$n" && continue
  err "$link: mirrors no skill — a project skill lives in $PROJECT_ROOT and is linked from here"
done

[[ $fail -eq 0 ]] || exit 1
echo "check-skills: $total skills validated ($(printf '%s' "$project_names" | grep -c .) project, $(printf '%s' "$user_names" | grep -c .) user)"
