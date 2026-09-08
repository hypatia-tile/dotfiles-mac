-- Neovim as the editor for text fields in the browser (Firefox).
--
-- The plugin is inert in a terminal Neovim: it only takes over when the
-- browser extension starts the instance, which is the case this config never
-- otherwise sees. That is also why it is not lazy-loaded — upstream's spec
-- loads it at startup, and the cost is a plugin that checks one variable.
--
-- `build` writes *outside this repository*, which nothing here declares: a
-- native messaging manifest per detected browser, pointing at a launcher
-- script under ~/.local/share/firenvim. A browser it does not detect is
-- skipped with a message rather than failing, which is what keeps this inert
-- in CI. Re-run `:call firenvim#install(0)` if the plugin is reinstalled or a
-- manifest goes missing.
--
-- **Detection is not "is the browser installed".** firenvim decides per
-- browser by testing one directory, and for Firefox on macOS that directory is
-- ~/Library/Application Support/Mozilla — not the profile directory, which is
-- ~/Library/Application Support/Firefox. A machine with Firefox and no native
-- messaging host yet has the second and not the first, so the first install
-- here silently skipped Firefox and wrote Chrome's manifest only. Measured,
-- then fixed by creating the directory once:
--
--   mkdir -p ~/Library/Application\ Support/Mozilla/NativeMessagingHosts
--
-- `firenvim#install(1)` would force every browser instead, at the price of
-- creating manifest directories for browsers that are not installed.
--
-- The launcher it writes is a snapshot of the environment at install time. It
-- resolves `nvim` from PATH and falls back to /etc/profiles/per-user/... rather
-- than a raw store path, so garbage collection cannot break the editor itself —
-- but the PATH it exports does contain store paths (ripgrep, procps) that a
-- collection would dangle. Re-running the install refreshes them.
--
-- The browser extension is a separate, manual install:
-- https://addons.mozilla.org/firefox/addon/firenvim/
return {
  "glacambre/firenvim",
  build = function()
    -- The installer writes to $XDG_DATA_HOME/firenvim, which NVIM_APPNAME does
    -- *not* isolate. bin/check runs under NVIM_APPNAME=nvim-dev precisely so it
    -- cannot disturb the real environment, and without this guard it does:
    -- installing firenvim there rewrote the shared launcher with
    -- NVIM_APPNAME='nvim-dev' baked in, so the browser would have started the
    -- dev config instead of this one. Observed on the first run of the check
    -- after adding this plugin, not reasoned about.
    if vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME ~= "nvim" then
      vim.notify("firenvim: skipping install under NVIM_APPNAME=" .. vim.env.NVIM_APPNAME, vim.log.levels.INFO)
      return
    end
    -- The plugin has to be on the runtimepath for its autoload function to
    -- resolve; `build` runs before a normal startup load would have happened.
    require("lazy").load { plugins = { "firenvim" }, wait = true }
    vim.fn["firenvim#install"](0)
  end,
  init = function()
    -- Read by the extension when it connects, so it must be set before the
    -- plugin loads rather than in `config`.
    --
    -- Upstream's defaults for the catch-all pattern, with one change:
    -- takeover = "never". The default "always" hands *every* textarea to
    -- Neovim on focus, search boxes included; "never" means <C-e> is what
    -- asks for it.
    vim.g.firenvim_config = {
      localSettings = {
        [".*"] = {
          cmdline = "neovim",
          content = "text",
          priority = 0,
          selector = "textarea",
          takeover = "never",
        },
      },
    }
  end,
}
