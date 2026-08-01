-- Bootstrap lazy.nvim and configure LazyVim base + our overrides
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        lazyrepo, lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- LazyVim setup with our overrides
require("lazy").setup({
    spec = {
        -- LazyVim core
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- LazyVim extras (uncomment to enable)
        -- { import = "lazyvim.plugins.extras.lang.typescript" },
        -- { import = "lazyvim.plugins.extras.lang.python" },
        -- { import = "lazyvim.plugins.extras.lang.go" },
        -- { import = "lazyvim.plugins.extras.lang.rust" },
        -- { import = "lazyvim.plugins.extras.coding.copilot" },
        -- { import = "lazyvim.plugins.extras.editor.harpoon2" },

        -- Our overrides + extra plugins
        { import = "plugins" },
    },
    defaults = {
        lazy = false,
        version = false,    -- always use the latest git commit
    },
    install = { colorscheme = { "gruvbox", "habamax" } },
    checker = { enabled = true, notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip", "matchit", "matchparen", "netrwPlugin",
                "tarPlugin", "tohtml", "tutor", "zipPlugin",
            },
        },
    },
})
