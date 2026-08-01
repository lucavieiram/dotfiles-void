-- Entry point — bootstraps lazy.nvim and loads our config under lua/
-- Adapted from LazyVim starter (https://github.com/LazyVim/starter)

require("config.lazy")

-- Gruvbox colorscheme (fixed — no runtime theme switching)
pcall(vim.cmd, "colorscheme gruvbox")
