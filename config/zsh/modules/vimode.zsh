#!/usr/bin/env zsh

# Vi mode configuration for zsh
# Provides a vim-like experience in the shell

# Enable vi mode
bindkey -v

# Reduce ESC delay to 10ms for faster mode switching
export KEYTIMEOUT=1

# Mode indicator variable
VI_MODE="[INS]"

# Cursor shape changes and mode indicator based on vi mode
# Beam cursor in insert mode, block cursor in normal mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    # Normal mode - block cursor
    echo -ne '\e[1 q'
    VI_MODE="[NOR]"
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    # Insert mode - beam cursor
    echo -ne '\e[5 q'
    VI_MODE="[INS]"
  fi
  zle reset-prompt
}
zle -N zle-keymap-select

# Initialize with beam cursor and insert mode on shell start
function zle-line-init {
  VI_MODE="[INS]"
  echo -ne "\e[5 q"
  zle reset-prompt
}
zle -N zle-line-init

# Reset cursor to beam when command is executed
preexec() {
  echo -ne '\e[5 q'
}

# Keep useful emacs-style keybindings in insert mode
bindkey '^A' beginning-of-line    # Ctrl+A - go to beginning
bindkey '^E' end-of-line          # Ctrl+E - go to end
bindkey '^R' history-incremental-search-backward  # Ctrl+R - reverse search
bindkey '^W' backward-kill-word   # Ctrl+W - delete word backward
bindkey '^U' backward-kill-line   # Ctrl+U - delete to beginning
bindkey '^K' kill-line            # Ctrl+K - delete to end
bindkey '^P' up-line-or-history   # Ctrl+P - previous command
bindkey '^N' down-line-or-history # Ctrl+N - next command

# Arrow keys work in insert mode
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history

# Vi-style history search in normal mode
bindkey -M vicmd 'k' up-line-or-history
bindkey -M vicmd 'j' down-line-or-history
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Vim-like undo/redo
bindkey -M vicmd 'u' undo
bindkey -M vicmd '^R' redo

# VI_MODE variable is set by zle-keymap-select and zle-line-init
# and is used in PROMPT in .zshrc

# Re-apply zsh-abbr's key bindings. `bindkey -v` above replaces the whole `main`
# keymap, so both of them went with it: Space stopped expanding abbreviations
# and control-space — zsh-abbr's plain space — became `undefined-key`. Only the
# first was restored here before; the second was silently dead.
#
# The list is abbr.zsh's, not this file's. The module glob in .zshrc sorts
# `abbr` before `vimode`, so the function is defined by now; the guard is for
# the case where it is not, which is harmless — loaded the other way round,
# zsh-abbr binds after `bindkey -v` and needs no help.
if (( ${+functions[abbr-bindkeys]} )); then
  abbr-bindkeys
fi
