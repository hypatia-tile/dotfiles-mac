# Payloads for every host that runs this configuration (ADR 0034).
#
# Home Manager is the only placer, and only places: payloads stay plain files
# under config/ (ADR 0020), and this file is a flat list of target-to-source
# entries. Leaving Home Manager means moving this list, nothing more, which is
# what keeps the choice interim.
#
# Imported by this flake and, by path, by hypatia-tile/nixos-config through a
# `flake = false` input. It therefore needs nothing from this flake's inputs,
# and a rename here breaks that repository's evaluation.
#
# Links point into the working tree, so an edit is live on save and
# `git status` reports it. Granularity follows runtime state, not preference:
# a directory is linked whole only where this repository owns every entry in
# it, and file by file where the tool writes beside them (#94).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.payloads;
  link = path: config.lib.file.mkOutOfStoreSymlink "${cfg.checkoutPath}/${path}";

  # User-scope agent skills (ADR 0028), linked per skill into both agents:
  # Claude Code reads ~/.claude/skills, Codex reads ~/.codex/skills, and
  # cursor-agent reads both. Never per directory: Codex keeps its own .system/
  # there, and an agent may create a skill of its own beside these.
  # bin/check-skills.sh fails a skill under config/agents/skills missing here.
  skills = [
    "clangd-check"
    "conversation-language"
    "github-language"
    "grilling"
    "handoff"
    "host-environment"
    "improvement-chat"
    "scrap-note"
    "step-review"
    "step-setup"
    "step-start"
    "vuln-triage"
  ];
  skillLinks = lib.listToAttrs (
    lib.concatMap (
      name:
      map
        (agent: {
          name = "${agent}/skills/${name}";
          value.source = link "config/agents/skills/${name}";
        })
        [
          ".claude"
          ".codex"
        ]
    ) skills
  );
in
{
  options.payloads.checkoutPath = lib.mkOption {
    type = lib.types.str;
    description = ''
      Absolute path to the dotfiles-mac checkout on this host. Payloads are
      linked into it, so moving the checkout leaves them dangling.
    '';
  };

  config = {
    xdg.configFile = {
      "git".source = link "config/git";
      "tmux".source = link "config/tmux";
      "kitty".source = link "config/kitty";
      "alacritty".source = link "config/alacritty";
      "lazygit".source = link "config/lazygit";

      # herdr writes logs, session.json, sessions/ and .plugins.lock beside it.
      "herdr/config.toml".source = link "config/herdr/config.toml";

      # ~/.config/zsh is ZDOTDIR, and zsh writes .zcompdump and `history` into
      # it, so the directory is not linked; modules/ and complete/ hold no
      # runtime state and are.
      #
      # `abbr add` and `abbr erase` replace `abbreviations` with an `mv`, which
      # turns this link into a regular file the next switch backs up and
      # discards. They are not used: edit the file in this repository, or use
      # `abbr add --session` for one shell.
      "zsh/.zshrc".source = link "config/zsh/.zshrc";
      "zsh/.zprofile".source = link "config/zsh/.zprofile";
      "zsh/.zshenv".source = link "config/zsh/.zshenv";
      "zsh/abbreviations".source = link "config/zsh/abbreviations";
      "zsh/modules".source = link "config/zsh/modules";
      "zsh/complete".source = link "config/zsh/complete";

      # Linked whole, which makes lazy-lock.json and lazyvim.json writable so
      # the editor can record plugin updates. Anything else nvim writes belongs
      # in stdpath("data") (docs/operations.md §1).
      "nvim".source = link "config/nvim";
    };

    home.file = skillLinks // {
      # The ZDOTDIR bootstrap: zsh reads it before ZDOTDIR exists.
      ".zshenv".source = link "config/zshenv";

      # Executables of this repository's own, on PATH through sessionPath
      # below. Linked whole: nothing else writes into the directory.
      ".local/share/dotfiles/bin".source = link "config/bin";

      # User-scope agent instructions (ADR 0033). A store copy, not a link: it
      # is the entry point to a safeguard, and a safeguard the agents it guards
      # can rewrite is not one. A change goes live at the next switch.
      ".claude/CLAUDE.md".source = ../../../config/agents/instructions.md;
      ".codex/AGENTS.md".source = ../../../config/agents/instructions.md;
    };

    home.sessionPath = [ "${config.home.homeDirectory}/.local/share/dotfiles/bin" ];

    # SKK L dictionary for skkeleton in Neovim. A package output, not a payload
    # of this repository; the writable user dictionary lives in nvim's own data
    # directory and is not managed here.
    xdg.dataFile."skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
  };
}
