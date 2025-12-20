local Snacks = require("snacks")

local M = {}

local function read_user_secrets_id(csproj)
	for _, line in ipairs(vim.fn.readfile(csproj)) do
		local raw = line:match("<UserSecretsId>%s*(.-)%s*</UserSecretsId>")
		if raw and raw ~= "" then
			return raw:gsub("^%s*(.-)%s*$", "%1")
		end
	end
end

local function find_csproj(start_dir)
	local matches = vim.fs.find(function(name, path)
		return name:match("%.csproj$")
	end, { path = start_dir, upward = true, limit = 1, type = "file" })

	if matches[1] then
		return matches[1]
	end

	-- Fall back to the current working directory if the buffer isn't inside a project
	matches = vim.fs.find(function(name)
		return name:match("%.csproj$")
	end, { path = start_dir, limit = 5, type = "file" })

	return matches[1]
end

local function candidate_paths(secrets_id)
	local paths = {}

	if vim.env.APPDATA and vim.env.APPDATA ~= "" then
		local win_path = vim.env.APPDATA:gsub("\\", "/")
		table.insert(paths, ("%s/Microsoft/UserSecrets/%s/secrets.json"):format(win_path, secrets_id))
	end

	table.insert(paths, vim.fn.expand(("~/.microsoft/usersecrets/%s/secrets.json"):format(secrets_id)))

	return paths
end

local function find_user_secrets()
	local bufname = vim.api.nvim_buf_get_name(0)
	local start_dir = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
	local csproj = find_csproj(start_dir)

	if not csproj then
		return nil, "No .csproj found near the current buffer"
	end

	local secrets_id = read_user_secrets_id(csproj)
	if not secrets_id then
		return nil, ("<UserSecretsId> not found in %s"):format(csproj)
	end

	local searched = {}
	for _, path in ipairs(candidate_paths(secrets_id)) do
		table.insert(searched, path)
		if vim.uv.fs_stat(path) then
			return {
				id = secrets_id,
				path = path,
				csproj = csproj,
			}
		end
	end

	return nil, ("User secrets file not found (checked: %s)"):format(table.concat(searched, ", "))
end

function M.open_picker()
	local info, err = find_user_secrets()
	if not info then
		Snacks.notify(err, { level = vim.log.levels.WARN, title = "User Secrets" })
		return
	end

	Snacks.picker.files({
		title = ("User Secrets (%s)"):format(info.id),
		cwd = vim.fs.dirname(info.path),
		hidden = true,
	})
end

return M
