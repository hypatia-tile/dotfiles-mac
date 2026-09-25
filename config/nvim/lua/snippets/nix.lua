local ls = require "luasnip"
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local fmta = require("luasnip.extras.fmt").fmta

-- Every body below is laid out the way nixfmt prints it, so the format-on-save
-- conform runs on a nix buffer leaves a fresh expansion alone. Checking a new
-- snippet means pasting its body into a flake and running `nixfmt --check`.

-- The nixpkgs ref is the string retyped most often. Cycle the ones that are
-- ever wanted with <C-K><C-E>; the last choice is free text for anything else.
local function nixpkgs_ref(pos)
  return c(pos, {
    t "nixos-unstable",
    t "nixpkgs-unstable",
    t "nixos-26.05",
    sn(nil, { i(1, "nixos-unstable") }),
  })
end

local function formatter_pkg(pos)
  return c(pos, {
    t "nixfmt-tree",
    t "nixfmt-rfc-style",
  })
end

local snippets = {
  -- The whole skeleton: inputs, eachDefaultSystem, devShells.default.
  s(
    { trig = "flake-template", desc = "flake.nix: flake-utils + devShells.default" },
    fmta(
      [[
{
  description = "<desc>";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<ref>";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            <packages>
          ];

          shellHook = ''
            <hook>
          '';
        };

        formatter = pkgs.<formatter>;
      }
    );
}
]],
      {
        desc = i(1, "description"),
        ref = nixpkgs_ref(2),
        packages = i(3, "hello"),
        hook = i(4, [[echo "dev shell ready"]]),
        formatter = formatter_pkg(5),
      }
    )
  ),

  s(
    { trig = "eachsystem", desc = "flake-utils.lib.eachDefaultSystem with pkgs bound" },
    fmta(
      [[
flake-utils.lib.eachDefaultSystem (
  system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    <body>
  }
);
]],
      { body = i(1) }
    )
  ),

  s({ trig = "pkgs-import", desc = "pkgs = import nixpkgs { inherit system; }" }, {
    c(1, {
      t "pkgs = import nixpkgs { inherit system; };",
      sn(
        nil,
        fmta(
          [[
pkgs = import nixpkgs {
  inherit system;
  overlays = [ <overlay> ];
};
]],
          { overlay = i(1, "rust-overlay.overlays.default") }
        )
      ),
    }),
  }),

  s(
    { trig = "devshell", desc = "devShells.default = pkgs.mkShell { … }" },
    fmta(
      [[
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    <packages>
  ];

  shellHook = ''
    <hook>
  '';
};
]],
      {
        packages = i(1, "hello"),
        hook = i(2, [[echo "dev shell ready"]]),
      }
    )
  ),

  s(
    { trig = "shellhook", desc = "shellHook = '' … ''" },
    fmta(
      [[
shellHook = ''
  <hook>
'';
]],
      { hook = i(1, [[echo "dev shell ready"]]) }
    )
  ),

  s(
    { trig = "packages-default", desc = "packages.default = pkgs.stdenv.mkDerivation { … }" },
    fmta(
      [[
packages.default = pkgs.stdenv.mkDerivation {
  pname = "<pname>";
  version = "<version>";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    <nativeBuildInputs>
  ];
};
]],
      {
        pname = i(1, "name"),
        version = i(2, "0.1.0"),
        nativeBuildInputs = i(3),
      }
    )
  ),

  s({ trig = "formatter", desc = "formatter = pkgs.nixfmt-tree" }, {
    t "formatter = pkgs.",
    formatter_pkg(1),
    t ";",
  }),

  s(
    { trig = "in-nixpkgs", desc = 'input: nixpkgs.url = "github:NixOS/nixpkgs/…"' },
    fmta([[nixpkgs.url = "github:NixOS/nixpkgs/<ref>";]], { ref = nixpkgs_ref(1) })
  ),

  s(
    { trig = "follows", desc = 'input: inputs.nixpkgs.follows = "nixpkgs"' },
    fmta([[<input>.inputs.nixpkgs.follows = "nixpkgs";]], { input = i(1, "home-manager") })
  ),
}

-- One trigger per upstream rather than one choice node with every URL in it:
-- blink.cmp lists snippets in the completion menu, so typing `in-` narrows the
-- list, which beats cycling choices. `follows` marks the inputs that take a
-- nixpkgs and so want pinning to ours — the line that is easiest to forget.
local common_inputs = {
  { trig = "in-flake-utils", name = "flake-utils", url = "github:numtide/flake-utils" },
  { trig = "in-flake-parts", name = "flake-parts", url = "github:hercules-ci/flake-parts" },
  { trig = "in-home-manager", name = "home-manager", url = "github:nix-community/home-manager", follows = true },
  { trig = "in-nix-darwin", name = "nix-darwin", url = "github:nix-darwin/nix-darwin", follows = true },
  { trig = "in-rust-overlay", name = "rust-overlay", url = "github:oxalica/rust-overlay", follows = true },
  { trig = "in-treefmt-nix", name = "treefmt-nix", url = "github:numtide/treefmt-nix", follows = true },
}

for _, spec in ipairs(common_inputs) do
  local body
  if spec.follows then
    body = t {
      spec.name .. " = {",
      '  url = "' .. spec.url .. '";',
      '  inputs.nixpkgs.follows = "nixpkgs";',
      "};",
    }
  else
    body = t(spec.name .. '.url = "' .. spec.url .. '";')
  end
  table.insert(snippets, s({ trig = spec.trig, desc = "input: " .. spec.url }, { body }))
end

return snippets
