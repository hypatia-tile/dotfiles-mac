-- Global, non-plugin keymaps. Loaded from init.lua after vim-options
-- (so mapleader is already set). Plugin- and LSP-specific keymaps live with
-- their features (lua/plugins/*, lua/lsp/keymaps.lua).
local keymap = require "shino.keymap"

-- Buffer navigation
keymap.nmap("H", ":bprevious<CR>", "Previous buffer")
keymap.nmap("L", ":bnext<CR>", "Next buffer")

-- Arrow keys resize the current window in normal mode
keymap.nmap("<Right>", "<c-w>>", "Increase window width")
keymap.nmap("<Left>", "<c-w><", "Decrease window width")
keymap.nmap("<Down>", "<c-w>-", "Decrease window height")
keymap.nmap("<Up>", "<c-w>+", "Increase window height")

-- Arrow keys insert literal Unicode arrows in insert mode
keymap.imap("<Right>", "→", "Insert → (right arrow)")
keymap.imap("<Left>", "←", "Insert ← (left arrow)")
keymap.imap("<Down>", "↓", "Insert ↓ (down arrow)")
keymap.imap("<Up>", "↑", "Insert ↑ (up arrow)")
