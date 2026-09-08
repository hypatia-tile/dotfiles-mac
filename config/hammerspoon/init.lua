-- Hammerspoon configuration
-- Managed by Home Manager (dotfiles-mac)

-- ===== Kitty Terminal Integration =====

-- Launch or focus Kitty with Cmd+Alt+K
hs.hotkey.bind({"cmd", "alt"}, "K", function()
  local kitty = hs.application.find("kitty")
  if kitty then
    kitty:activate()
  else
    hs.application.open("kitty")
  end
end)

-- ===== Window Management =====

-- Move window to left half
hs.hotkey.bind({"cmd", "alt"}, "Left", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(hs.geometry.rect(0, 0, 0.5, 1))
  end
end)

-- Move window to right half
hs.hotkey.bind({"cmd", "alt"}, "Right", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(hs.geometry.rect(0.5, 0, 0.5, 1))
  end
end)

-- Move window to top half
hs.hotkey.bind({"cmd", "alt"}, "Up", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(hs.geometry.rect(0, 0, 1, 0.5))
  end
end)

-- Move window to bottom half
hs.hotkey.bind({"cmd", "alt"}, "Down", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToUnit(hs.geometry.rect(0, 0.5, 1, 0.5))
  end
end)

-- Maximize window
hs.hotkey.bind({"cmd", "alt"}, "M", function()
  local win = hs.window.focusedWindow()
  if win then
    win:maximize()
  end
end)

-- Center window
hs.hotkey.bind({"cmd", "alt"}, "C", function()
  local win = hs.window.focusedWindow()
  if win then
    win:centerOnScreen()
  end
end)

-- ===== Display Management =====

-- Move window to next display
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Right", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(win:screen():next())
  end
end)

-- Move window to previous display
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Left", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(win:screen():previous())
  end
end)

-- ===== Japanese Input Pad =====
--
-- This machine has no system IME: Japanese is typed with skkeleton inside
-- Neovim. Every text box outside Neovim therefore has no good input path, and
-- browser-side attempts at closing that gap were tried and abandoned. This
-- closes it from the other side: cmd-alt-I opens a small Neovim window, and
-- what is written there goes to the clipboard.
--
-- <C-s> in either mode copies the whole buffer to the system clipboard, saves,
-- and closes the window. macOS then returns focus to the application that had
-- it, where Cmd-V delivers the text. Pasting is deliberately left manual:
-- synthesizing the keystroke means tracking the previous application and
-- replaying input, which fails in ways that are hard to read.
--
-- The buffer is one fixed file rather than a temporary one, so closing by
-- accident does not lose what was written.
--
-- The window is kept out of the tiling layout by aerospace.toml, which matches
-- the title `inputpad` that `kitty --title` fixes.
local input_pad_dir = os.getenv("HOME") .. "/.local/state/inputpad"

hs.hotkey.bind({"cmd", "alt"}, "I", function()
  -- Reuse the window if it is already open: a second one would be a second
  -- buffer on the same file, which Neovim would rightly complain about.
  local existing = hs.window.find("inputpad")
  if existing then
    existing:focus()
    return
  end

  -- Started detached rather than with hs.execute, which is synchronous and
  -- would block Hammerspoon for as long as the editor is open. `sh -lc` so the
  -- login shell's PATH finds kitty and nvim.
  local command = table.concat({
    "mkdir -p '" .. input_pad_dir .. "'",
    -- kitty remembers the size of the last window it opened, which made the
    -- pad inherit whatever the working terminal was — full screen. These
    -- overrides apply to this instance only, so ordinary kitty windows keep
    -- remembering. 80x20 cells is a comment box, not an editor.
    "exec kitty --title=inputpad"
      .. " -o remember_window_size=no"
      .. " -o initial_window_width=80c"
      .. " -o initial_window_height=20c"
      .. " -e nvim"
      .. " -c \"nnoremap <buffer> <C-s> <Cmd>%y+<CR><Cmd>wqa<CR>\""
      .. " -c \"inoremap <buffer> <C-s> <Esc><Cmd>%y+<CR><Cmd>wqa<CR>\""
      .. " -c startinsert"
      .. " '" .. input_pad_dir .. "/pad.md'",
  }, " && ")
  hs.task.new("/bin/sh", nil, {"-lc", command}):start()
end)

-- ===== Configuration Reload =====

-- Reload Hammerspoon config with Cmd+Alt+R
hs.hotkey.bind({"cmd", "alt"}, "R", function()
  hs.reload()
end)
hs.alert.show("Hammerspoon config loaded")
