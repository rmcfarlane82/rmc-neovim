local scroll = require("config.snacks-scroll")
local statuscolumn = require("config.snacks-statuscolumn")
local picker = require("config.snacks-picker")
local explorer = require("config.snacks-explorer")


return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		explorer = explorer,
		indent = { enabled = true },
		input = { enabled = true },
		keymap = { enabled = true },
		picker = picker,
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = scroll,
		statuscolumn = statuscolumn,
		words = { enabled = true },
		terminal = {
			enabled = true,
			shell = vim.fn.has("win32") == 1 and { "pwsh.exe", "-NoLogo" } or nil,
		},
		animate = { enabled = true },
		bufdelete = { enabled = true },
		zen = { enabled = true },
	},
	keys = {
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log({
					finder = "git_log",
					format = "git_log",
					preview = "git_show",
					confirm = "git_checkout",
					layout = { preset = "vertical" },
				})
			end,
			desc = "Git Log"
		},
    { "<leader>gb", function() Snacks.picker.git_branches({
			layout = "select",
			on_show = function()
				vim.cmd.stopinsert()
			end,
		}) end, desc = "Git Branches" },
    { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },



		{
			"<leader>ff",
			function()
				Snacks.picker.smart({
					layout = { preset = "ivy" },
				})
			end,
			desc = "Smart Find Files"
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers({
					-- Focus the list so we don't auto-enter insert mode
					on_show = function()
						vim.cmd.stopinsert()
					end,
					finder = "buffers",
					format = "buffer",
					hidden = false,
					unloaded = true,
					current = true,
					sort_lastused = true,
					win = {
						input = {
							keys = {
								["d"] = "bufdelete",
							},
						},
						list = { keys = { ["d"] = "bufdelete" } },
					},
				})
			end,
			desc = "Buffers"
		},
		{ "<leader>fg", function() Snacks.picker.grep() end,            desc = "Grep" },
		{ "<leader>fh", function() Snacks.picker.command_history() end, desc = "Command History" },
		{ "<leader>fn", function() Snacks.picker.notifications() end,   desc = "Notification History" },
		{ "<leader>e",  function() Snacks.explorer() end,               desc = "File Explorer" },
	},
}
