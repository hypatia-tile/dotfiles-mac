#!/usr/bin/env zsh

# Load the zsh-abbr plugin from the Home Manager profile
# (zsh-abbr in modules/home/packages.nix). Note the path differs from the
# Homebrew layout this replaced: share/zsh/zsh-abbr, not share/zsh-abbr.
# The plugin resolves its own directory with ${0:A:h}, so sourcing through
# the profile symlink still finds the zsh-job-queue it bundles.
source /etc/profiles/per-user/$USER/share/zsh/zsh-abbr/zsh-abbr.zsh

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
