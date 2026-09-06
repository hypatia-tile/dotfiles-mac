local au = require "shino.autocmd"

au.autocmd("BufEnter", "Drop auto-comment continuation (c/r/o) from formatoptions", {
  callback = function()
    vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
  end,
})

-- Project a config payload as soon as it is saved.
--
-- ~/.config is a read-only projection of the dotfiles-mac checkout (ADR 0026),
-- and the projector is run by hand. This closes that loop for edits made in
-- Neovim, which is where nearly all of them happen: saving anything under the
-- checkout's config/ runs bin/project.sh, so the change is live without
-- remembering a command.
--
-- Scope is the whole config/ tree, not just this payload. Neovim is the editor
-- for zsh and tmux configuration too, and a hook that covered only its own
-- would leave "which payload was that again?" as something to remember.
--
-- The checkout is found by walking up from the saved file rather than
-- hardcoded, so this is inert in any tree that is not a dotfiles-mac checkout
-- — including someone else's, and including this config placed anywhere else.
--
-- Synchronous on purpose: the projector costs about 0.06s warm, and running it
-- in the background would hide its failures until the next `--check`.
au.autocmd("BufWritePost", "Project config payloads after saving one", {
  pattern = "*",
  callback = function(args)
    local file = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
    if file == "" then
      return
    end

    -- The marker has to be a *direct child* of the directory being tested:
    -- vim.fs.root only inspects each ancestor's own entries, so a nested path
    -- is never seen. flake.nix finds a flake root; bin/project.sh then says
    -- whether it is one with a projector in it.
    --
    -- Only that one path is checked, and the choice is deliberate (#87). This
    -- hook previously also confirmed the declaration file by name, and when
    -- that file was renamed the check kept naming the old one: the hook
    -- returned early on every save and projected nothing, silently, while the
    -- projector itself still worked. Coupling to bin/project.sh cannot fail
    -- that way — if the path is wrong there is genuinely nothing to run, so
    -- returning is the correct behaviour rather than a hidden one. Whether the
    -- declaration exists is the projector's business, and it says so loudly.
    local root = vim.fs.root(file, "flake.nix")
    if not root or vim.fn.executable(root .. "/bin/project.sh") ~= 1 then
      return
    end
    if not vim.startswith(file, root .. "/config/") then
      return
    end

    local out = vim.system({ root .. "/bin/project.sh" }, { text = true }):wait()
    if out.code ~= 0 then
      vim.notify("project.sh failed:\n" .. (out.stderr or "") .. (out.stdout or ""), vim.log.levels.ERROR)
    end
  end,
})
