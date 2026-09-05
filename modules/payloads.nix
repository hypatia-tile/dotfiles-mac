# Payloads projected into $HOME by bin/project.sh (ADR 0026).
#
# Plain data, deliberately outside modules/home/files.nix: a payload declared
# there is *placed* by Home Manager, and there is no declare-without-placing.
# Keeping the two lists disjoint is what stops a path acquiring two owners —
# the constraint ADR 0001 was written to establish, and the reason a partition
# works where "retire files.nix entirely" never could.
#
# Read with `nix eval -f`, which costs 0.15s and needs neither the flake nor
# Home Manager.
#
#   <target relative to $HOME> = {
#     source = <path relative to the checkout>;
#     mode   = "copy" | "link";
#   };
#
# `copy` is a read-only copy and is the default disposition: it is what makes
# ~/.config a projection rather than an editing surface.
#
# `link` is a symlink to the working tree, for the case a copy cannot serve —
# a file the tool must write *back into the repository*. A writable copy is not
# an option there, because it diverges from the repository instead of updating
# it. Declare `link` per path, never per payload, so that each exception stays
# visible.
{
  ".config/git" = {
    source = "config/git";
    mode = "copy";
  };
}
