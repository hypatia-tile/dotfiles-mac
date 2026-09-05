local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("flake-template", {
    t { "{", '  description = "' },
    i(1, "description"),
    t { '";', "" },
    t {
      "  inputs = {",
      '    nixpkgs.url = "' .. 'github:NixOS/nixpkgs/nixos-unstable";',
      '    flake-utils.url = "' .. 'github:numtide/flake-utils";',
      "  };",
      "  outputs = {",
      "    self,",
      "    nixpkgs,",
      "    flake-utils,",
      "  }:",
      "    flake-utils.lib.eachDefaultSystem (",
      "      system: let",
      "        pkgs = import nixpkgs {inherit system;};",
      "      in {",
      "        devShells.default = pkgs.mkShell {",
      "          buildInputs = with pkgs; [",
      "            ",
    },
    i(2, "buildInputs"),
    t {
      "",
      "          ];",
      "         };",
      "         shellHook = ''",
      "           ",
    },
    i(3, 'echo "Shell Hook"'),
    t {
      "",
      "         '';",
      "       }",
      "     );",
      "}",
    },
  }),
}
