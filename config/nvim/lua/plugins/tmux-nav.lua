return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Tmux: Navigate left" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Tmux: Navigate down" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Tmux: Navigate up" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Tmux: Navigate right" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Tmux: Navigate previous" },
  },
}
