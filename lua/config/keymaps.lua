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

keymap("n", "<leader>lr", function()
	if vim.fn.exists(":LspRestart") == 2 then
		vim.cmd("LspRestart")
	end
end, { desc = "Restart LSP" })

keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP rename" })

keymap("n", "<leader>d", function()
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local opts = { focus = true, scope = "cursor" }
	if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
		opts.scope = "line"
	end
	vim.diagnostic.open_float(nil, opts)
end, { desc = "Diagnostic float" })

keymap("n", "<leader>D", function()
	Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })

keymap("n", "<leader>lv", function()
	local current = vim.diagnostic.config().virtual_text
	local enabled = current ~= false
	vim.diagnostic.config({ virtual_text = not enabled })
	vim.notify(
		"Diagnostics virtual text " .. (enabled and "disabled" or "enabled"),
		vim.log.levels.INFO,
		{ title = "LSP" }
	)
end, { desc = "Diagnostics virtual text toggle" })

-- Resize splits (Ctrl + Alt + direction)
keymap("n", "<C-A-h>", ":vertical resize +2<CR>", { desc = "Expand vertical split" })
keymap("n", "<C-A-l>", ":vertical resize -2<CR>", { desc = "Shrink vertical split" })
keymap("n", "<C-A-j>", ":resize +2<CR>", { desc = "Expand horizontal split" })
keymap("n", "<C-A-k>", ":resize -2<CR>", { desc = "Shrink horizontal split" })
keymap("n", "<leader>lr", ":LspRestart<CR>", { desc = "Lsp Restart" })

-- somewhere in your LSP setup
--keymap({ "i", "n", "s" }, "<C-s>", "<Plug>(nvim.lsp.ctrl-s)", {
--  silent = true,
--  desc = "Cycle signature overload",
--})
-- Cycle through bufferline tabs with Ctrl+n / Ctrl+p
--keymap("n", "<C-n>", "<cmd>BufferLineCycleNext<CR>", { desc = "Bufferline: Next buffer" })
--keymap("n", "<C-p>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Bufferline: Previous buffer" })
--keymap("n", "<leader>q", close_buffer_keep_window, { desc = "Close current buffer" })
vim.keymap.set("n", "<leader>dt", function()
    require("dotnet_tests").run_nearest_test()
  end, { desc = "Run nearest dotnet test" })

vim.keymap.set("n", "<leader>df", function()
    require("dotnet_tests").run_test_in_file()
  end, { desc = "Run a test from this file" })

 vim.keymap.set("n", "<leader>dp", function()
    require("dotnet_tests").run_all_tests_in_project()
  end, { desc = "Run all tests in project" })

vim.keymap.set("n", "<leader>dP", function() require("dotnet_tests").pick_project_and_run_tests() end, { desc = "Pick .NET test project" })

vim.keymap.set("n", "<leader>de", function()
    require("dotnet_tests").open_test_explorer()
  end, { desc = "Open Dotnet Test Explorer" })


