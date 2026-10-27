#!/usr/bin/env zsh

# Line editor key bindings: the Emacs keymap, with one way out into the editor.

# Explicit, not left to zsh: with no `bindkey` call zsh picks the vi keymap
# whenever $EDITOR or $VISUAL contains "vi", and $EDITOR is nvim.
bindkey -e

# Delete from the cursor to the start of the line, as bash, readline and macOS
# text fields do. The Emacs keymap binds it to `kill-whole-line`.
bindkey '^U' backward-kill-line

# Edit the command line in $VISUAL (or $EDITOR, so nvim) — bash's binding for
# the same thing. The Emacs keymap leaves ^X^E unbound.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Let ^S reach the line editor as `history-incremental-search-forward`, the way
# back from an overshot ^R. With FLOW_CONTROL on (zsh's default) the terminal
# keeps ^S as "stop output" at the prompt and freezes it, and ^Q, the way out,
# is the tmux and herdr prefix here. Running programs keep flow control.
unsetopt FLOW_CONTROL

# A beam cursor at every prompt. nvim and other full-screen programs can exit
# leaving a block cursor, and the shell would otherwise keep it.
function zle-line-init {
  echo -ne '\e[5 q'
}
zle -N zle-line-init

# Re-apply zsh-abbr's key bindings. `bindkey -e` above replaces the whole `main`
# keymap, as `bindkey -v` did before it, so both of them go with it: Space
# stops expanding abbreviations and control-space — zsh-abbr's plain space —
# becomes `undefined-key`.
#
# The list is abbr.zsh's, not this file's. The module glob in .zshrc sorts
# `abbr` before `keymap`, so the function is defined by now; the guard is for
# the case where it is not, which is harmless — loaded the other way round,
# zsh-abbr binds after `bindkey -e` and needs no help.
if (( ${+functions[abbr-bindkeys]} )); then
  abbr-bindkeys
fi
