-- Follows the system theme: ~/.cache/theme/nvim.lua is written by theme-apply.
-- Loads after gruvbox.lua (alphabetical), so its colorscheme wins; gruvbox stays the fallback.
return {
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    { "rose-pine/neovim", name = "rose-pine", lazy = true },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = function()
                local f = vim.fn.expand("~/.cache/theme/nvim.lua")
                if vim.fn.filereadable(f) == 1 then dofile(f) else vim.cmd.colorscheme("gruvbox") end
            end,
        },
    },
}
