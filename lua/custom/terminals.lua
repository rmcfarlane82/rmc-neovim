local Snacks = require("snacks")

local M = {}

local function short_command(meta)
	local cmd = meta.cmd
	if type(cmd) == "table" then
		cmd = table.concat(cmd, " ")
	end
	if type(cmd) ~= "string" or cmd == "" then
		return nil
	end

	local first = cmd:match("^%s*(%S+)")
	if not first then
		return nil
	end

	return vim.fs.basename(first)
end

local function orientation_label(position)
	if position == "left" or position == "right" then
		return "vertical"
	end
	if position == "top" or position == "bottom" then
		return "horizontal"
	end
	if position == "float" then
		return "float"
	end
	return nil
end

local function terminal_orientation(term, meta)
	meta = meta or (term and term.buf and vim.api.nvim_buf_is_valid(term.buf) and vim.b[term.buf].snacks_terminal)
	if meta and meta.orientation then
		return orientation_label(meta.orientation) or meta.orientation
	end
	if term and term.opts and term.opts.position then
		return orientation_label(term.opts.position) or term.opts.position
	end
	return nil
end

local function set_terminal_orientation(term, position)
	if not (term and term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
		return
	end
	local meta = vim.b[term.buf].snacks_terminal or {}
	meta.orientation = position
	vim.b[term.buf].snacks_terminal = meta
end

local function terminal_id(term)
	if not (term and term.buf) then
		return nil
	end
	local meta = vim.b[term.buf] and vim.b[term.buf].snacks_terminal or {}
	local id = meta.id or term.id or term.buf
	return tonumber(id) or id
end

local function terminal_label(term)
	if not term or not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
		return ("Terminal #%s [closed]"):format(term and term.id or "?")
	end

	local meta = vim.b[term.buf].snacks_terminal or {}
	local id = terminal_id(term) or "?"
	local cmd = short_command(meta)
	local state = term:win_valid() and "open" or "hidden"
	local orient = terminal_orientation(term, meta)
	local state_bits = orient and ("%s · %s"):format(state, orient) or state

	if cmd then
		return ("#%s Terminal (%s) [%s]"):format(id, cmd, state_bits)
	end

	return ("#%s Terminal [%s]"):format(id, state_bits)
end

local function terminal_items(terms)
	table.sort(terms, function(a, b)
		local ida, idb = terminal_id(a), terminal_id(b)
		if type(ida) == "number" and type(idb) == "number" then
			return ida < idb
		end
		return tostring(ida) < tostring(idb)
	end)

	local items = {}
	for _, term in ipairs(terms) do
		items[#items + 1] = {
			text = terminal_label(term),
			term = term,
			item = term,
			key = tostring(term.id or term.buf),
		}
	end
	return items
end

local function term_from_item(item)
	return item and (item.term or item.item) or nil
end

local function with_term(item, fn)
	local term = term_from_item(item)
	if not term then
		return
	end
	return term, fn and fn(term)
end

local function refocus_picker_list(picker)
	local win = picker and picker.list and picker.list.win and picker.list.win.win or nil
	if win and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_set_current_win, win)
	end
end

local function ensure_picker_open(picker)
	if picker and not picker.closed then
		return
	end
	local remaining = Snacks.terminal.list()
	if #remaining > 0 then
		vim.schedule(function()
			M.pick_terminal_to_close()
		end)
	end
end

function M.pick_terminal_to_close()
	local terms = Snacks.terminal.list()
	if #terms == 0 then
		vim.notify("No terminals to close", vim.log.levels.INFO, { title = "Terminals" })
		return
	end

	local reopen_on_close = true

	Snacks.picker.pick({
		source = "terminals",
		prompt = "Select a terminal",
		finder = function()
			return terminal_items(Snacks.terminal.list())
		end,
		format = function(item)
			return { { terminal_label(item.term or item.item) } }
		end,
		preview = function(ctx)
			ctx.preview:reset()
			local term = ctx.item and (ctx.item.term or ctx.item.item) or nil
			local buf = term and term.buf
			if not (buf and vim.api.nvim_buf_is_valid(buf)) then
				ctx.preview:notify("Terminal closed", "warn")
				return
			end

			ctx.preview:set_title(terminal_label(term))
			ctx.preview:set_buf(buf)
			ctx.preview:loc()
		end,
		focus = "list",
		auto_close = false,
		show_empty = true,
		layout = { preset = "default" },
		on_close = function()
			if not reopen_on_close then
				return
			end
			ensure_picker_open()
		end,
		actions = {
			confirm = function(picker, item)
				local term = with_term(item)
				if not term then
					return
				end
				vim.schedule(function()
					if not term:buf_valid() then
						return
					end
					local ok, err = pcall(function()
						term:show()
						term:focus()
					end)
					if not ok then
						vim.notify(("Could not open terminal: %s"):format(err), vim.log.levels.ERROR,
							{ title = "Terminals" })
						return
					end
					reopen_on_close = false
					if not picker.closed then
						picker:close()
					end
				end)
			end,
			open_keep = function(picker, item)
				local term = with_term(item)
				if not term then
					return
				end
				vim.schedule(function()
					if not term:buf_valid() then
						return
					end
					local ok, err = pcall(function()
						term:show()
					end)
					if not ok then
						vim.notify(("Could not open terminal: %s"):format(err), vim.log.levels.ERROR,
							{ title = "Terminals" })
						return
					end
					picker:refresh()
					refocus_picker_list(picker)
				end)
			end,
			close_term = function(picker, item)
				local term = with_term(item)
				if not term then
					return
				end
				vim.schedule(function()
					if term:buf_valid() then
						local ok, err = pcall(term.hide, term)
						if not ok then
							vim.notify(("Could not close terminal: %s"):format(err), vim.log.levels.ERROR,
								{ title = "Terminals" })
							return
						end
					end
					picker:refresh()
					refocus_picker_list(picker)
					ensure_picker_open(picker)
				end)
			end,
			delete = function(picker, item)
				local term = with_term(item)
				if not term then
					return
				end
				vim.schedule(function()
					if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
						local ok, err = pcall(term.close, term)
						if not ok then
							vim.notify(("Could not close terminal: %s"):format(err), vim.log.levels.ERROR,
								{ title = "Terminals" })
							return
						end
					end
					picker:refresh()
					refocus_picker_list(picker)
					ensure_picker_open(picker)
				end)
			end,
			close_picker = function(picker)
				reopen_on_close = false
				if not picker.closed then
					picker:close()
				end
			end,
		},
		win = {
			list = {
				keys = {
					["<cr>"] = "confirm",
					c = "close_term",
					d = "delete",
					o = "open_keep",
					q = "close_picker",
				},
				wo = {
					number = false,
					relativenumber = false,
				},
			},
		},
	})
end

function M.toggle(position, opts)
	opts = opts or {}
	local count = (opts.base or 0) + (vim.v.count > 0 and vim.v.count or 1)
	local merged = vim.tbl_deep_extend("force", {
		count = count,
		cwd = vim.fn.getcwd(-1, -1), -- keep a stable id even if window-local cwd changes
		win = {
			position = position,
			height = opts.height,
			width = opts.width,
			border = opts.border,
		},
	}, opts)

	local term = Snacks.terminal.toggle(nil, merged)
	set_terminal_orientation(term, merged.win.position)
	return term
end

return M
