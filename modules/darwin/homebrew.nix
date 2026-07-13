# Homebrew stays only for GUI casks and macOS-specific builds (ADR 0005).
# Expected removals at first activation, all confirmed in the inventory:
# aquaskk (unused), orphaned formulas libidn2/nettle/p11-kit, and the
# emacs -> emacs-app correction.
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall"; # declared-only; "zap" deferred

    brews = [
      "llvm"
      "make"
      "cmake"
      "olets/tap/zsh-abbr"
    ];

    casks = [
      "hammerspoon"
      "nikitabobko/tap/aerospace"
      "emacs-app"
    ];

    masApps = { };
  };
}
