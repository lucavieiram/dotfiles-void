-- Custom autocmds. LazyVim provides a useful base set; this file extends it.

local augroup = vim.api.nvim_create_augroup

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("yank_highlight", { clear = true }),
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

