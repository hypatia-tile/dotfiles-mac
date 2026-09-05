return {
  root_dir = function(bufnr, callback)
    -- Undesirable file patterns
    local fname = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
    local disable_patterns = { "env", "conf", "local", "private" }
    local is_disabled = vim.iter(disable_patterns):any(function(pattern)
      return string.match(fname, pattern)
    end)
    if is_disabled then
      return
    end
    local root_dir = vim.fs.root(bufnr, { ".git" })
    if root_dir then
      return callback(root_dir)
    end
  end,
  on_init = function()
    local hl = require "shino.highlight"
    hl.extend("ComplHint", "Comment", { underline = true })
    hl.extend("ComplHintMore", "MoreMsg", { underline = true })
    -- Enable inline completion via LspAttach autocmd
    local au = require "shino.autocmd"
    au.autocmd("LspAttach", "Set up Copilot inline completion keymaps on attach", {
      group = au.group "CopilotAttach",
      callback = function(args)
        local bufnr = args.buf
        -- Enable inline completion
        vim.lsp.inline_completion.enable(false, { bufnr = bufnr })

        local keymap = require "shino.keymap"
        keymap.imap("<c-e>", function()
          vim.lsp.inline_completion.get()
          if vim.fn.pumvisible() == 1 then
            return "<c-e>"
          end
        end, "Copilot: Trigger inline completion", { expr = true, buffer = bufnr })
        -- Select inline completions
        keymap.imap("<c-f>", function()
          vim.lsp.inline_completion.select()
        end, "Copilot: Next inline completion", { buffer = bufnr })
        keymap.imap("<c-b>", function()
          vim.lsp.inline_completion.select { count = -1 * vim.v.count1 }
        end, "Copilot: Previous inline completion", { buffer = bufnr })
        keymap.nmap("<leader>tc", function()
          vim.lsp.inline_completion.enable(not vim.lsp.inline_completion.is_enabled())
        end, "Toggle Copilot Suggestions", { buffer = bufnr })
      end,
    })
  end,
}
