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
    -- **The extension caches this.** Editing the table below changes nothing in
    -- the browser until "Reload settings" is pressed in the firenvim popup (the
    -- toolbar icon) and the page is reloaded. Querying the native messaging
    -- host directly shows the new settings immediately, which makes the two
    -- disagree in a way that reads as "the change had no effect" — it cost an
    -- hour here before the popup was tried.
    --
    -- Upstream's defaults for the catch-all pattern. takeover = "always" is
    -- upstream's default and is kept deliberately: the selector is `textarea`
    -- only, so single-line inputs and search boxes are never touched, and the
    -- point of this plugin here is Japanese input — there is no system IME on
    -- this machine, skkeleton in the frame is how a browser text box gets
    -- Japanese, and a keystroke to ask for it first is friction on every use.
    --
    -- Verified end to end on a plain textarea: the frame opens on focus and
    -- <C-j> toggles skkeleton inside it.
    vim.g.firenvim_config = {
      localSettings = {
        [".*"] = {
          cmdline = "neovim",
          content = "text",
          priority = 0,
          selector = "textarea",
          takeover = "always",
        },
        -- Cosense (and scrapbox.io, its former name) runs its own editor over
        -- a textarea it keeps pulling focus back to. A frame opened there
        -- flickers, accepts no input, and the page's own keybindings keep
        -- firing — measured, and not something this side can win. An empty
        -- selector matches no element, which is how a site is opted out.
        ["https?://(scrapbox\\.io|cosense\\.io)/"] = {
          priority = 1,
          selector = "",
        },
      },
    }
  end,
}
