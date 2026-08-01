-- Options loaded before lazy.nvim startup — see LazyVim docs.

-- Make Space the leader (standard LazyVim)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- General editor defaults
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.undofile = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"   -- system clipboard

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Better completion experience
vim.opt.completeopt = "menu,menuone,noinsert,noselect"
vim.opt.pumheight = 10

-- Faster updatetime helps for which-key + gitsigns
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
