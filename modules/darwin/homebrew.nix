# Homebrew stays only for GUI casks and macOS-specific builds (ADR 0005).
#
# Emacs is no longer one of them. It comes from Nix, pinned and patched in
# hypatia-tile/emacs-flake (ADR 0031), so emacs-plus@30 and the whole runtime
# tree it dragged along -- around forty formulae -- leave the machine at the
# next activation. That is the intended removal, and it is large: read the
# cleanup output rather than skimming it.
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall"; # declared-only; "zap" deferred

    taps = [ ];

    brews = [
      "make"
      "cmake"
      # Declared for vterm, which compiles its native module on first use and
      # needs cmake and libtool for it.
      #
      # This entry is not redundant. libtool used to be installed only as
      # imagemagick's dependency, and imagemagick was declared only because
      # emacs-plus@30 linked against it -- both of which left with ADR 0031.
      # Without this line cleanup would take libtool too, and the loss would
      # not surface until the next time that module had to be rebuilt. That is
      # the shape of #57, which cost four weeks; naming the dependency is
      # cheaper than rediscovering it.
      "libtool"
    ];

    casks = [
      "hammerspoon"
      "nikitabobko/tap/aerospace"
      # Full macOS GUI Tailscale (Network Extension: MagicDNS, exit nodes,
      # subnet routes at the OS level). The plain `tailscale` cask name now
      # resolves to `tailscale-app`; the `tailscale` Homebrew *formula* is the
      # CLI-only build, which is deliberately not used here (ADR 0005 keeps
      # Homebrew to GUI casks).
      "tailscale-app"
      # Launcher, on trial. Its hotkey is Cmd+Opt+Space, not the default
      # Cmd+Space: Spotlight keeps Cmd+Space. That chord is macOS symbolic
      # hotkey 65 (Show Finder search window), disabled in macos.nix — without
      # that declaration both fire on the same chord, and a manual disable in
      # System Settings would be undone at the next activation, because
      # nix-darwin replaces the whole AppleSymbolicHotKeys dictionary.
      "raycast"
      # The system input method (ADR 0029). Chosen over aquaskk — which this
      # file's header records as removed at first activation — for one feature:
      # its 直接入力 list bypasses conversion per Bundle Identifier, so kitty
      # and Emacs keep C-j for skkeleton and ddskk.
      #
      # The cask is the whole of what is declared. Its input sources, its
      # dictionary and that list live inside the application's sandbox
      # container and are set by hand after the switch; ADR 0029 says why
      # declaring them was rejected rather than missed.
      "macskk"
    ];

    masApps = { };
  };
}
