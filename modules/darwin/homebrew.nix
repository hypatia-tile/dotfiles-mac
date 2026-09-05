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
      # (Homebrew 6.0.0 enabled HOMEBREW_REQUIRE_TAP_TRUST). Tap-level trust
      # covers the formula regardless of how the brews entry names it.
      {
        name = "d12frosted/emacs-plus";
        trusted = true;
      }
    ];

    brews = [
      "make"
      "cmake"
      "olets/tap/zsh-abbr"
      # emacs-plus@30 links against imagemagick (and its libtiff dependency)
      # because of --with-imagemagick below, but imagemagick is only an
      # *optional* dependency of the formula. Declare it explicitly so
      # onActivation.cleanup does not uninstall it (which left Emacs unable
      # to load libtiff.6.dylib at runtime). Declaring imagemagick also keeps
      # libtiff, since libtiff is a dependency of imagemagick.
      "imagemagick"
      {
        # Fully qualified on purpose. `brew bundle cleanup` builds its keep-set
        # by matching each Brewfile entry against the installed formulae's
        # `full_name`; a bare "emacs-plus@30" never matches
        # "d12frosted/emacs-plus/emacs-plus@30", so cleanup walked none of this
        # formula's dependencies and proposed deleting its whole runtime tree
        # (40 formulae — gcc, gnutls, librsvg, cairo, sqlite, …). See issue #57.
        #
        # emacs-plus@30 enables native-compilation (aot) unconditionally, so
        # there is no --with-native-comp option; --with-poll does not exist on
        # @30 either. Only imagemagick is a valid extra option here.
        name = "d12frosted/emacs-plus/emacs-plus@30";
        args = [ "with-imagemagick" ];
        link = true;
      }
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
    ];

    masApps = { };
  };
}
