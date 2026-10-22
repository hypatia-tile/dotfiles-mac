{ pkgs, ... }:
let
  common = import ../common.nix;

  # The packaged WordNet index is sorted in plain lowercase byte order, but
  # dictd's binary search compares the way dictfmt sorts — case folded,
  # punctuation ignored — so about one plain word in seven (`hello`,
  # `gallery`) was not found (#286). Re-sorting the index that way finds
  # every headword; the data file is used as it is.
  wordnet = pkgs.runCommand "dict-db-wordnet-resorted" { } ''
    src=${pkgs.dictdDBs.wordnet}/share/dictd
    mkdir -p $out/share/dictd
    ln -s $src/wn.dict $out/share/dictd/wn.dict
    LC_ALL=C sort -t "$(printf '\t')" -k1,1 -d -f $src/wn.index > $out/share/dictd/wn.index
  '';
  wiktionary = "${pkgs.dictdDBs.wiktionary}/share/dictd";

  # Offline English dictionary server for `def` (config/zsh/modules/dict.zsh)
  # and dict.nvim (#287), on the loopback interface only.
  dictdConf = pkgs.writeText "dictd.conf" ''
    global {
      listen_to 127.0.0.1
      port 2628
    }
    access { allow 127.0.0.1 }
    database wn {
      data "${wordnet}/share/dictd/wn.dict"
      index "${wordnet}/share/dictd/wn.index"
    }
    database wiktionary {
      name "English Wiktionary (2024-09-01)"
      data "${wiktionary}/wiktionary-en.dict.dz"
      index "${wiktionary}/wiktionary-en.index"
    }
  '';
in
{
  home = {
    inherit (common) username homeDirectory;
    # Set on initial configuration: 2026-01-02.
    # Do not change unless migrating or reinstalling.
    stateVersion = "25.05";

    sessionPath = [
      "${common.homeDirectory}/.nix-profile/bin"
      "/etc/profiles/per-user/${common.username}/bin"
      "/run/current-system/sw/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      # Carried from the retired $HOME/.envrc (inventory A-13): the direnv
      # mechanism is excluded, only its variables survive.
      NVIM_FLOATING_MEMO_DIR = "${common.homeDirectory}/github/Memo";
      JAVA_HOME = "${pkgs.jdk21_headless.home}";
    };
  };

  xdg.enable = true;

  # Auto-start Hammerspoon at login. The app is a Homebrew cask (phase 3);
  # its configuration is placed by payloads/darwin.nix.
  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # `-d nodetach` keeps dictd in the foreground, which is what launchd
  # supervises. Left to its defaults it logs every word looked up; `-l none`
  # leaves only the start-up and error lines, on stderr.
  launchd.agents.dictd = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.dict}/bin/dictd"
        "-c"
        "${dictdConf}"
        "-d"
        "nodetach"
        "-l"
        "none"
      ];
      StandardErrorPath = "${common.homeDirectory}/Library/Logs/dictd.log";
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
