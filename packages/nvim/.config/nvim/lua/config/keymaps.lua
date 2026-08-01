-- Custom keymaps. LazyVim provides a huge default set; this file adds tweaks.

local map = vim.keymap.set

-- Quick save
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map("i", "<C-s>", "<Esc><cmd>w<cr>",  { desc = "Save" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Move lines up/down (visual mode)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Better paste in visual mode (don't yank the replaced text)
map("v", "p", "P", { desc = "Paste (keep register)" })

-- Quick yank to system clipboard (in case clipboard option is reset somewhere)
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- Open cheatsheet from inside nvim
map("n", "<leader>h?",
    function() vim.cmd("!cheatsheet.sh vim") end,
    { desc = "Open vim cheatsheet (external)" })
