# Homebrew stays only for GUI casks and macOS-specific builds (ADR 0005).
# Expected removals at first activation, all confirmed in the inventory:
# aquaskk (unused) and orphaned formulas libidn2/nettle/p11-kit. Emacs is
# provided by the d12frosted/emacs-plus tap's emacs-plus@30 formula (built
# from source); the old emacs-app cask is removed by cleanup on activation.
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall"; # declared-only; "zap" deferred

    taps = [
      # Non-official tap: must be trusted for activation to load its formulae
      # (Homebrew 6.0.0 enabled HOMEBREW_REQUIRE_TAP_TRUST). emacs-plus@30 is
      # not a fully-qualified name, so trust must come from the tap itself.
      {
        name = "d12frosted/emacs-plus";
        trusted = true;
      }
    ];

    brews = [
      "llvm"
      "make"
      "cmake"
      "olets/tap/zsh-abbr"
      {
        name = "emacs-plus@30";
        args = [
          "with-native-comp"
          "with-imagemagick"
          "with-poll"
        ];
        link = true;
      }
    ];

    casks = [
      "hammerspoon"
      "nikitabobko/tap/aerospace"
    ];

    masApps = { };
  };
}
