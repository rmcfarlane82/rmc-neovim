-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("i", "jk", "<Esc>", { desc = "Leave insert mode" })
vim.keymap.set("v", "jk", "<Esc>", { desc = "Leave visual mode" })
vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Leave terminal insert mode" })
vim.keymap.set("c", "jk", "<C-c>", { desc = "Leave command mode" })

vim.keymap.set("n", "<C-e>", function()
  require("snacks").explorer()
end, { desc = "Open file explorer" })

-- remove default resize mappings
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

vim.keymap.set("n", "<C-M-h>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<C-M-l>", ":vertical resize +2<CR>")
vim.keymap.set("n", "<C-M-k>", ":resize +2<CR>")
vim.keymap.set("n", "<C-M-j>", ":resize -2<CR>")
