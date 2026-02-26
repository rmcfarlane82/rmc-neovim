local M = {}
local Snacks = require("snacks")

local function is_test_project(path)
	local name = vim.fs.basename(path):lower()

	-- Match common test naming patterns, e.g. Foo.Tests.csproj, Foo-Test.csproj, tests.unit.csproj
	return name:match("[._-]tests?%.csproj$") or name:match("[._-]tests?[._-]") or name:match("[._-]test%.csproj$")
end

local function find_csprojs(root)
	local cwd = root or vim.fn.getcwd(-1, -1)
	local files = vim.fs.find(function(name)
		return name:match("%.csproj$")
	end, { path = cwd, type = "file", limit = 200 })

	table.sort(files)

	return vim.tbl_filter(function(path)
		return not is_test_project(path)
	end, files)
end

function M.has_projects(root)
	return #find_csprojs(root) > 0
end

local function read_launch_profiles(csproj)
	local dir = vim.fs.dirname(csproj)
	local candidates = {
		vim.fs.joinpath(dir, "Properties", "launchSettings.json"),
		vim.fs.joinpath(dir, "properties", "launchSettings.json"),
	}

	for _, path in ipairs(candidates) do
		if vim.uv.fs_stat(path) then
			local ok, json = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), "\n"))
			if ok and type(json) == "table" and type(json.profiles) == "table" then
				local profiles = vim.tbl_keys(json.profiles)
				table.sort(profiles)
				return profiles, path
			end
		end
	end

	return {}, nil
end

local function open_runner_terminal(cmd, cwd)
	Snacks.terminal(cmd, {
		cwd = cwd,
		win = {
			position = "bottom",
			height = 0.32,
		},
	})
end

local function run_project(csproj, profile)
	local project_dir = vim.fs.dirname(csproj)
	local cmd = { "dotnet", "run", "--project", csproj }

	if profile and profile ~= "" then
		table.insert(cmd, "--launch-profile")
		table.insert(cmd, profile)
	end

	open_runner_terminal(cmd, project_dir)
end

local function choose_profile_and_run(csproj, profiles, launch_path)
	local label_for_launch = launch_path and vim.fn.fnamemodify(launch_path, ":.") or "launchSettings.json"
	local options = { "Default (no launch profile)" }
	vim.list_extend(options, profiles)

	vim.ui.select(options, {
		prompt = ("Launch profile [%s]"):format(label_for_launch),
	}, function(choice, idx)
		if not choice then
			return
		end

		local profile = idx == 1 and nil or choice
		run_project(csproj, profile)
	end)
end

function M.pick_and_run()
	local root = vim.fn.getcwd(-1, -1)
	local csprojs = find_csprojs(root)
	if #csprojs == 0 then
		vim.notify(("No .csproj files found under %s"):format(root), vim.log.levels.WARN, { title = "Dotnet Run" })
		return
	end

	vim.ui.select(csprojs, {
		prompt = "Select .csproj to run",
		format_item = function(item)
			return vim.fn.fnamemodify(item, ":.")
		end,
	}, function(selection)
		if not selection then
			return
		end

		local profiles, launch_path = read_launch_profiles(selection)
		if #profiles == 0 then
			run_project(selection)
			return
		end

		choose_profile_and_run(selection, profiles, launch_path)
	end)
end

function M.setup()
	vim.api.nvim_create_user_command("DotnetRun", M.pick_and_run, {
		desc = "Pick a .csproj and launch profile for dotnet run",
	})
end

return M
