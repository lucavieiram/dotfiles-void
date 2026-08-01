-- Gruvbox colorscheme override.
-- Set as LazyVim's active colorscheme so all plugins inherit the palette.
return {
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        opts = {
            terminal_colors = true,
            italic = {
                strings    = false,
                comments   = true,
                operators  = false,
                folds      = true,
            },
            contrast = "hard",            -- 'soft', 'medium' (default), 'hard'
            transparent_mode = false,
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "gruvbox",
        },
    },
}
