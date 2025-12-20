local M = {}

local function run_test_file(path)
	local Snacks = require("snacks")
	local neotest = require("neotest")
	local short = vim.fn.fnamemodify(path, ":t")
	Snacks.notify(("Running tests in %s"):format(short), { title = "Neotest" })
	neotest.run.run(path)
end

function M.pick_test_file()
	local Snacks = require("snacks")
	Snacks.picker.files({
		title = "Test files (*.cs)",
		glob = {
			"**/*[Tt]est*.cs",
			"**/*[Tt]ests*.cs",
			"**/Tests/**/*.cs",
			"**/Test/**/*.cs",
		},
		confirm = function(picker, item)
			picker:close()
			if item and item.file then
				run_test_file(item.file)
			end
		end,
	})
end

function M.pick_test()
	local Snacks = require("snacks")
	local neotest = require("neotest")

	local items = {}
		for _, adapter_id in ipairs(neotest.state.adapter_ids()) do
			local tree = neotest.state.positions(adapter_id)
			if tree then
				for _, data in tree:iter() do
					if data.type == "test" then
						items[#items + 1] = {
							id = data.id,
							name = data.name,
						file = data.path or data.id,
						line = data.range and (data.range[1] + 1) or nil,
						adapter = adapter_id,
					}
				end
			end
		end
	end

	if vim.tbl_isempty(items) then
		Snacks.notify("No discovered tests yet. Open a test file first.", { level = "warn", title = "Neotest" })
		return
	end

	Snacks.picker.select(items, {
		prompt = "Run which test?",
		format_item = function(item)
			local rel = vim.fn.fnamemodify(item.file, ":.")
			local line = item.line and (":" .. item.line) or ""
			return ("%s%s — %s"):format(rel, line, item.name)
		end,
	}, function(item)
		if not item then
			return
		end
		neotest.run.run(item.id)
	end)
end

return M
