_:
let
  common = import ../common.nix;
in
{
  # Run the projector on every switch (ADR 0026). Home Manager triggers it but
  # places nothing itself, so no path acquires a second owner.
  #
  # Ordered after linkGeneration because the migration path depends on it: Home
  # Manager releases a payload it no longer declares, and only then can the
  # projector claim that target.
  #
  # This covers the direction that does not announce itself. Editing a payload
  # and forgetting to project is self-revealing — the change appears not to
  # work — whereas a `git pull` that moves the repository leaves a stale
  # read-only copy running silently.
  home.activation.projectPayloads = ''
    run ${common.checkoutPath}/bin/project.sh
  '';
}
