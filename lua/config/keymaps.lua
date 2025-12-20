local Snacks = require("snacks")
local line_numbers = require("custom.line_numbers")
local keymap = Snacks.keymap.set

line_numbers.setup()
keymap("n", "<C-e>", function()
	Snacks.explorer()
end, { desc = "Explorer" })

keymap("n", ";", ":", { desc = "Command mode", silent = false })

keymap({ "n", "v" }, "<Esc>", function()
	vim.cmd.nohlsearch()
	return "<Esc>"
end, { expr = true, desc = "Clear search highlight" })

keymap("i", "jk", "<Esc>", { desc = "Leave insert mode" })
keymap("v", "jk", "<Esc>", { desc = "Leave visual mode" })
keymap("t", "jk", [[<C-\><C-n>]], { desc = "Leave terminal insert mode" })
keymap("c", "jk", "<C-c>", { desc = "Leave command mode" })
keymap("n", "<leader>ul", function()
	line_numbers.cycle()
end, { desc = "Line number modes" })
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
keymap("n", "<C-n>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<C-p>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

keymap("n", "ge", function()
	vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.HINT } })
end, { desc = "Next diagnostic" })

keymap("n", "<leader>mv", function()
	require('render-markdown').toggle()
end, { desc = "Markdown Preview" })

-- Resize splits (Ctrl + Alt + direction)
keymap("n", "<C-A-h>", ":vertical resize +2<CR>", { desc = "Expand vertical split" })
keymap("n", "<C-A-l>", ":vertical resize -2<CR>", { desc = "Shrink vertical split" })
keymap("n", "<C-A-j>", ":resize +2<CR>", { desc = "Expand horizontal split" })
keymap("n", "<C-A-k>", ":resize -2<CR>", { desc = "Shrink horizontal split" })

-- somewhere in your LSP setup
--keymap({ "i", "n", "s" }, "<C-s>", "<Plug>(nvim.lsp.ctrl-s)", {
--  silent = true,
--  desc = "Cycle signature overload",
--})
-- Cycle through bufferline tabs with Ctrl+n / Ctrl+p
--keymap("n", "<C-n>", "<cmd>BufferLineCycleNext<CR>", { desc = "Bufferline: Next buffer" })
--keymap("n", "<C-p>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Bufferline: Previous buffer" })
--keymap("n", "<leader>q", close_buffer_keep_window, { desc = "Close current buffer" })
