local M = {}

local state_file = vim.fn.stdpath("data") .. "/snacks_explorer_width"
local default_width = 40

local function read_width()
	local ok, data = pcall(vim.fn.readfile, state_file)
	if ok and data and data[1] then
		local w = tonumber(data[1])
		if w and w > 0 then
			return w
		end
	end
	return default_width
end

local function save_width(w)
	pcall(vim.fn.writefile, { tostring(w) }, state_file)
end

local function get_explorer_list_win()
	local ok, Snacks = pcall(require, "snacks")
	if not ok then return nil end
	local pickers = Snacks.picker.get({ source = "explorer" })
	local explorer = pickers and pickers[1]
	if not explorer then return nil end
	local list = explorer.list
	if not (list and list.win and list.win.win) then return nil end
	return list.win.win
end

function M.setup()
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			local wins = vim.v.event and vim.v.event.windows or {}
			if #wins == 0 then return end
			local explorer_win = get_explorer_list_win()
			if not explorer_win then return end
			for _, win in ipairs(wins) do
				if win == explorer_win and vim.api.nvim_win_is_valid(win) then
					save_width(vim.api.nvim_win_get_width(win))
					break
				end
			end
		end,
	})
end

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
