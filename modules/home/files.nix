{ config, pkgs, ... }:
let
  common = import ../common.nix;

  # Payloads are linked to this checkout's working tree, not copied into the
  # store (ADR 0021): editing a file takes effect on save, and the repository
  # stays the only surface through which configuration changes, because every
  # edit is one `git status` reports.
  #
  # Link granularity follows runtime state, not preference. A directory-level
  # link hands the directory to the repository, so anything the tool writes
  # there lands in the working tree. Link whole directories only where the
  # repository owns every entry; link file-by-file where it does not.
  link = path: config.lib.file.mkOutOfStoreSymlink "${common.checkoutPath}/${path}";
in
{
  home.file = {
    # ZDOTDIR bootstrap — the whole zsh setup depends on it (inventory A-14).
    ".zshenv".source = link "config/zshenv";
  };

  xdg.configFile = {
    # zsh writes .zcompdump and HISTFILE into ZDOTDIR, so the directory itself
    # must stay a real directory: its files are linked one by one. The three
    # subdirectories hold no runtime state and are linked whole, which means a
    # new module needs no switch at all — only a new *link* does.
    "zsh/.zshrc".source = link "config/zsh/.zshrc";
    "zsh/.zprofile".source = link "config/zsh/.zprofile";
    "zsh/.zshenv".source = link "config/zsh/.zshenv";
    "zsh/abbr-definitions.zsh".source = link "config/zsh/abbr-definitions.zsh";
    "zsh/modules".source = link "config/zsh/modules";
    "zsh/complete".source = link "config/zsh/complete";
    "zsh/functions".source = link "config/zsh/functions";

    # Most payloads are no longer here: they are projected read-only by
    # bin/project.sh from modules/payloads.nix (ADR 0026). Home Manager must
    # not declare those, or the path would have two owners — declaring
    # without placing is not possible, which is why the projector's
    # declaration lives outside this file. What remains below is what has not
    # been migrated yet; zsh is last because a broken shell cannot be
    # repaired from, and a generation rollback does not undo a projection.

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
