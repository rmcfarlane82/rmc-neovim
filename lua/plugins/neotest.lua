local neotest_runner = require("config.neotest-runner")

return {
	"nvim-neotest/neotest",
	dependencies = {
		"Issafalcon/neotest-dotnet",
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"antoinemadec/FixCursorHold.nvim",
	},
	keys = {
		{ "<leader>tn", function() require("neotest").run.run() end,                        desc = "Test nearest" },
		{ "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,     desc = "Test file" },
		{ "<leader>ta", function() require("neotest").run.run({ suite = true }) end,       desc = "Test suite (project/solution)" },
		{ "<leader>ts", function() require("neotest").summary.toggle() end,                desc = "Test summary" },
		{ "<leader>to", function() require("neotest").output.open({ enter = true }) end,   desc = "Test output" },
		{ "<leader>tp", function() require("neotest").output.open({ enter = false, short = true, last_run = true }) end, desc = "Test preview (float)" },
		{ "<leader>tO", function() require("neotest").output_panel.toggle() end,           desc = "Test output panel" },
		{ "<leader>tt", function() neotest_runner.pick_test() end,                         desc = "Test picker (Snacks)" },
		{ "<leader>tF", function() neotest_runner.pick_test_file() end,                    desc = "Test file (Snacks picker)" },
	},
	opts = function()
		return {
			adapters = {
				require("neotest-dotnet")({
					-- Change to "solution" if you want discovery to start at the solution root
					discovery_root = "solution",
				}),
			},
			status = { virtual_text = true },
			output = { open_on_run = false },
			summary = {
				follow = true,
				open = "botright split | resize 15",
			},
			discovery = {
				-- Skip heavy/unrelated directories when searching for tests
				filter_dir = function(name, rel_path, root)
					local ignore = {
						[".git"] = true,
						[".idea"] = true,
						[".vscode"] = true,
						["bin"] = true,
						["obj"] = true,
						["node_modules"] = true,
						["packages"] = true,
						["dist"] = true,
						["build"] = true,
					}
					if ignore[name] then
						return false
					end
					return true
				end,
			},
		}
	end,
	config = function(_, opts)
		require("neotest").setup(opts)
	end,
}
