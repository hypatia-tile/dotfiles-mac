{ config, pkgs, ... }:
let
  common = import ../common.nix;

  # The two payloads that stay with Home Manager are linked to this checkout's
  # working tree, not copied into the store (ADR 0021): editing a file takes
  # effect on save, and the repository stays the only surface through which
  # configuration changes, because every edit is one `git status` reports.
  # Everything else is projected read-only instead (ADR 0026).
  #
  # Link granularity follows runtime state, not preference. A directory-level
  # link hands the directory to the repository, so anything the tool writes
  # there lands in the working tree. Link whole directories only where the
  # repository owns every entry; link file-by-file where it does not.
  link = path: config.lib.file.mkOutOfStoreSymlink "${common.checkoutPath}/${path}";
in
{
  xdg.configFile = {
    # The payloads are no longer here: they are projected read-only by
    # bin/project.sh from modules/payloads.tsv (ADR 0026). Home Manager must
    # not declare those, or the path would have two owners — declaring
    # without placing is not possible, which is why the projector's
    # declaration lives outside this file. What remains below is what stays
    # here permanently; both entries have a reason that does not expire.

    # Stays with Home Manager, permanently. Projecting it once left the machine
    # with nothing placed: the declaration was a Nix file, `nix eval` needs the
    # experimental features this payload enables, and the failure arrived after
    # Home Manager had released the path (#85). Reading the declaration without
    # a parser removed that particular cycle, so the reason this entry stays is
    # now the narrower one bin/project.sh states at SELF_DEPENDENCIES: the guard
    # refuses the path, and a build that fails is what stops it being moved back
    # without knowing why (ADR 0026).
    "nix".source = link "config/nix";

    # Neovim is a payload of this repository since the import (ADR 0021,
    # ADR 0023). The directory is linked whole, which makes lazy-lock.json
    # writable so the editor can record plugin updates — but writes still
    # belong in stdpath("data"); the directory being writable is not an
    # invitation to use it (docs/operations.md §1).
    "nvim".source = link "config/nvim";
  };

  # SKK L dictionary for skkeleton in Neovim (inventory C-6: provided from
  # nixpkgs instead of vendoring). Stays a store path: it is a package output,
  # not a payload of this repository. The nvim config reads it from
  # ~/.local/share/skk; the writable user dictionary lives in nvim's own data
  # dir and is not managed here.
  xdg.dataFile."skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
}
