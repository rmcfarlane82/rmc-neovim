local Snacks = require("snacks")
local scroll = require("config.snacks-scroll")
local statuscolumn = require("config.snacks-statuscolumn")
local picker = require("config.snacks-picker")
local user_secrets = require("config.user_secrets")
local dotnet_runner = require("config.dotnet-runner")
local terminals = require("custom.terminals")
local buffer_sidebar_width = 50

dotnet_runner.setup()

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
		dashboard = {
			enabled = true,
			preset = {
				---@type snacks.dashboard.Item[]
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
					{ icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{ icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
					{ icon = " ", key = "M", desc = "Mason", action = ":Mason", enabled = package.loaded.lazy ~= nil },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
███╗   ██╗███████╗██████╗ ██████╗
████╗  ██║██╔════╝██╔══██╗██╔══██╗
██╔██╗ ██║█████╗  ██████╔╝██║  ██║
██║╚██╗██║██╔══╝  ██╔══██╗██║  ██║
██║ ╚████║███████╗██║  ██║██████╔╝
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝
]],
			},
		},
		explorer = { enabled = true },
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
			interactive = false, -- stay in normal mode by default
			start_insert = false,
			auto_insert = false,
			shell = vim.fn.has("win32") == 1 and { "pwsh.exe", "-NoLogo" } or nil,
		},
		scratch = { enabled = false },
		animate = { enabled = true },
		bufdelete = { enabled = true },
		zen = { enabled = true },
		dim = { enabled = true },
		gitbrowse = { enabled = true },
		lazygit = {
			-- Close the terminal buffer when lazygit exits to avoid lingering "process exited" messages
			auto_close = true,
			interactive = true, -- enter insert for lazygit, even though other terminals default to normal
			start_insert = true,
			auto_insert = true,
			theme = {
				[241]                      = { fg = "Special" },
				activeBorderColor          = { fg = "LazyGitActiveBorder", bold = true },
				cherryPickedCommitBgColor  = { fg = "Identifier" },
				cherryPickedCommitFgColor  = { fg = "Function" },
				defaultFgColor             = { fg = "Normal" },
				inactiveBorderColor        = { fg = "FloatBorder" },
				optionsTextColor           = { fg = "Function" },
				searchingActiveBorderColor = { fg = "MatchParen", bold = true },
				selectedLineBgColor        = { bg = "Visual" }, -- set to `default` to have no background colour
				unstagedChangesColor       = { fg = "DiagnosticError" },
			},
		},
	},
	keys = function()
		local mappings = {
			{
				"<A-h>",
				function()
					terminals.toggle("bottom")
				end,
				desc = "Toggle terminal",
				mode = "t",
			},
			{
				"<A-h>",
				function()
					terminals.toggle("bottom")
				end,
				desc = "Toggle terminal",
			},
			{
				"<A-v>",
				function()
					terminals.toggle("right", { base = 100, width = 0.3 })
				end,
				desc = "Terminal vertical split (use count for new)",
			},
			{
				"<A-f>",
				function()
					terminals.toggle("float", { base = 200, width = 0.9, height = 0.9, border = "rounded" })
				end,
				desc = "Terminal float (use count for new)",
			},
			{
				"<leader>ft",
				terminals.pick_terminal_to_close,
				desc = "Close terminal (pick buffer)",
			},

			{
				"<leader>lh",
				function()
					local buf = vim.api.nvim_get_current_buf()
					local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
					vim.lsp.inlay_hint.enable(not enabled, { bufnr = buf })

					vim.notify(
						"Inlay hints " .. (enabled and "disabled" or "enabled"),
						vim.log.levels.INFO,
						{ title = "LSP" }
					)
				end,
				desc = "Inlay hints Toggle",
				mode = { "n" },
			},
			{
				"<leader>zd",
				function()
					Snacks.dim()
				end,
				desc = "Dim on",
			},
			{
				"<leader>zD",
				function()
					Snacks.dim.disable()
				end,
				desc = "Dim off",
			},
			{
				"<leader>zz",
				function()
					Snacks.zen.zen()
				end,
				desc = "Zen toggle",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log({
						on_show = function()
							vim.cmd.stopinsert()
						end,
						finder = "git_log",
						format = "git_log",
						preview = "git_show",
						confirm = "git_checkout",
						layout = { preset = "vertical" },
					})
				end,
				desc = "Log"
			},
			{
				"<leader>gb",
				function()
					Snacks.picker.git_branches({
						layout = "select",
						on_show = function()
							vim.cmd.stopinsert()
						end,
					})
				end,
				desc = "Branches"
			},
			{
				"<leader>gL",
				function()
					Snacks.picker.git_log_line({
						on_show = function()
							vim.cmd.stopinsert()
						end,
					}
					)
				end,
				desc = "Log Line"
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status({
						on_show = function()
							vim.cmd.stopinsert()
						end,
					})
				end,
				desc = "Status"
			},
			{ "<leader>gS", function() Snacks.picker.git_stash() end,                 desc = "Stash" },
			{
				"<leader>gd",
				function()
					Snacks.picker.git_diff({
						on_show = function()
							vim.cmd.stopinsert()
						end,
					}
					)
				end,
				desc = "Diff (Hunks)"
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_log_file({
						on_show = function()
							vim.cmd.stopinsert()
						end,
					}
					)
				end,
				desc = "Log File"
			},
			{ "<leader>ga", function() Snacks.lazygit() end,                          desc = "Lazy Git" },

			-- Github
			{ "<leader>gi", function() Snacks.picker.gh_issue() end,                  desc = "Issues (open)" },
			{ "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "Issues (all)" },
			{ "<leader>gp", function() Snacks.picker.gh_pr() end,                     desc = "Pull Requests (open)" },
			{ "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end,    desc = "Pull Requests (all)" },
			{ "<leader>gB", function() Snacks.gitbrowse.open() end,                   desc = "Browser" },

			{
				"<leader>ff",
				function()
					Snacks.picker.files({
						layout = { preset = "ivy" },
					})
				end,
				desc = "Find Files"
			},
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers({
						-- Focus the list so we don't auto-enter insert mode
						on_show = function()
							vim.cmd.stopinsert()
						end,
						layout = {
							preset = "sidebar",
							layout = {
								preview = "main",
								position = "right",
								width = buffer_sidebar_width,
								min_width = buffer_sidebar_width,
								max_width = buffer_sidebar_width,
							},
						},
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
			{ "<leader>fk", function() Snacks.picker.keymaps() end,         desc = "keymaps" },
			{
				"<leader>fg",
				function()
					Snacks.picker.grep({
						layout = {
							preset = "ivy",
						},
					})
				end,
				desc = "Grep"
			},
			{ "<leader>fh", function() Snacks.picker.command_history() end, desc = "Command History" },
			{ "<leader>fn", function() Snacks.picker.notifications() end,   desc = "Notification History" },
			{ "<leader>fu", function() user_secrets.open_picker() end,      desc = "User Secrets" },
		}

		if dotnet_runner.has_projects() then
			table.insert(mappings, {
				"<leader>fr",
				function()
					dotnet_runner.pick_and_run()
				end,
				desc = ".NET run (pick project/profile)",
			})
		end

		vim.list_extend(mappings, {
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			{
				"<C-e>",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			{ "<leader>fp", function() Snacks.picker.projects() end,              desc = "Projects" },

			{ "<leader>bd", function() Snacks.bufdelete() end,                    desc = "Delete current buffer" },

			-- LSP
			{ "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "Goto Definition" },
			{ "gD",         function() Snacks.picker.lsp_declarations() end,      desc = "Goto Declaration" },
			{ "gr",         function() Snacks.picker.lsp_references() end,        nowait = true,                  desc = "References" },
			{ "gi",         function() Snacks.picker.lsp_implementations() end,   desc = "Goto Implementation" },
			{ "gy",         function() Snacks.picker.lsp_type_definitions() end,  desc = "Goto T[y]pe Definition" },
			{ "gaI",        function() Snacks.picker.lsp_incoming_calls() end,    desc = "C[a]lls Incoming" },
			{ "gao",        function() Snacks.picker.lsp_outgoing_calls() end,    desc = "C[a]lls Outgoing" },
			{ "<leader>ls", function() Snacks.picker.lsp_symbols() end,           desc = "LSP Symbols" },
			{ "<leader>lS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
			{ "<leader>ld", function() Snacks.picker.diagnostics() end,           desc = "Workspace Diagnostics" },
			{ "<leader>lD", function() Snacks.picker.diagnostics_buffer() end,    desc = "Buffer Diagnostics" },
			{
				"<Space>.",
				function()
					require("actions-preview").code_actions()
				end,
				desc = "Code action"
			},
			{ "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, desc = "Format file" },

			{ "]]",         function() Snacks.words.jump(1, true) end,           desc = "Next Reference" },
			{ "[[",         function() Snacks.words.jump(-1, true) end,          desc = "Previous Reference" },
		})

		return mappings
	end,
}
