#!/usr/bin/env zsh

# zsh-abbr: abbreviations that expand as they are typed.

# The abbreviations live in $ZDOTDIR/abbreviations, which is zsh-abbr's own
# user-abbreviations file rather than a script of `abbr add` calls — the header
# there says why. This has to be set *before* the plugin is sourced: the plugin
# reads it at load time and loads the file immediately.
#
# Set explicitly rather than relying on the default. zsh-abbr's default is
# $ZDOTDIR/abbreviations when that file exists and
# ~/.config/zsh-abbr/user-abbreviations when it does not, and the fallback is a
# path this repository does not own — the one where abbreviations used to
# accumulate, one seeding at a time.
typeset -g ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/abbreviations

# Load the plugin from the Home Manager profile (zsh-abbr in
# modules/home/packages.nix). Note the path differs from the Homebrew layout
# this replaced: share/zsh/zsh-abbr, not share/zsh-abbr.
# The plugin resolves its own directory with ${0:A:h}, so sourcing through the
# profile symlink still finds the zsh-job-queue it bundles.
source /etc/profiles/per-user/$USER/share/zsh/zsh-abbr/zsh-abbr.zsh

# The key bindings zsh-abbr makes in the `main` keymap, in one place so that
# vimode.zsh does not have to know what they are. `bindkey -v` there replaces
# the whole keymap and takes both with it — space falls back to `self-insert`
# and control-space becomes `undefined-key`, which is worse than the plain
# space it is supposed to insert. vimode.zsh calls this afterwards.
#
# Only these two: `accept-line` is redefined as a widget
# (`zle -N accept-line abbr-expand-and-accept`) rather than bound to a key, so
# `bindkey -v` leaves expansion-on-Enter alone, and the `isearch` bindings live
# in their own keymap, which it does not touch. Both measured, not assumed.
abbr-bindkeys() {
  # Space expands an abbreviation; control-space is a plain space.
  bindkey " " abbr-expand-and-insert
  bindkey "^ " magic-space
}
