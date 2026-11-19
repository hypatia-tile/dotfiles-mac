-- One-off prompts to `fm`, the Apple Foundation Model CLI that macOS ships as
-- /usr/bin/fm. It needs Apple Intelligence and `sudo fm license` accepted
-- once per machine. setup() maps <leader>tf itself; the `keys` entry only
-- lets lazy.nvim load the plugin on that key.
return {
  "hypatia-tile/fm.nvim",
  cmd = "Fm",
  keys = { { "<leader>tf", desc = "Toggle fm prompt window" } },
  opts = {},
}
