#!/usr/bin/env zsh

# Load the zsh-abbr plugin from its Homebrew installation
# (olets/tap/zsh-abbr, declared in modules/darwin/homebrew.nix)
source /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh

# Function to load/reload abbreviation definitions
abbr-reload() {
  if [[ -f $ZDOTDIR/abbr-definitions.zsh ]]; then
    source $ZDOTDIR/abbr-definitions.zsh
    echo "Abbreviations reloaded from abbr-definitions.zsh"
  else
    echo "Error: abbr-definitions.zsh not found"
    return 1
  fi
}

# Only auto-load on first setup (when no abbreviations exist)
# To reload after editing abbr-definitions.zsh, run: abbr-reload
if [[ $(abbr list 2>/dev/null | wc -l) -eq 0 ]]; then
  abbr-reload
fi
