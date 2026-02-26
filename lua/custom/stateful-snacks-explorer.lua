local M = {}

-- Path to the file where the explorer width is persisted between sessions
local state_file = vim.fn.stdpath("data") .. "/snacks_explorer_width"
local default_width = 40

local function read_width()
	local success, data = pcall(vim.fn.readfile, state_file)
	if success and data and data[1] then
		local width = tonumber(data[1])
		if width and width > 0 then
			return width
		end
	end
	return default_width
end

local function save_width(width)
	pcall(vim.fn.writefile, { tostring(width) }, state_file)
end

-- Navigate the Snacks picker internals to get the explorer's list window handle
local function get_explorer_list_win()
	local success, Snacks = pcall(require, "snacks")
	if not success then return nil end
	local pickers = Snacks.picker.get({ source = "explorer" })
	local explorer = pickers and pickers[1]
	if not explorer then return nil end
	local list = explorer.list
	if not (list and list.win and list.win.win) then return nil end
	return list.win.win
end

-- Listen for window resize events and save the explorer width when it changes
function M.setup()
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			local windows = vim.v.event and vim.v.event.windows or {}
			if #windows == 0 then return end
			local explorer_win = get_explorer_list_win()
			if not explorer_win then return end
			for _, window in ipairs(windows) do
				if window == explorer_win and vim.api.nvim_win_is_valid(window) then
					save_width(vim.api.nvim_win_get_width(window))
					break
				end
			end
		end,
	})
end

-- Open the explorer, restoring the previously saved width
function M.open(opts)
	local width = read_width()
	opts = vim.tbl_deep_extend("force", {
		layout = {
			layout = {
				width = width,
			},
		},
	}, opts or {})
	return require("snacks").explorer(opts)
end

return M
