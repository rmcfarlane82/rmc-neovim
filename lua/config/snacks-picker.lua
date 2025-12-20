-- lua/config/snacks-picker.lua
local custom_vertical_preview_ratio = 0.75

---@type snacks.Config.picker
return {
	enabled = true,

	-- Folders to ignore
--	exclude = {},

	-- File name formatting
	formatters = {
		file = {
			filename_first = true,
			git_status_hl = false, -- keep folder/file colors stable; git signs still show
		},
	},
	win = {
		input = {
			keys = {
				-- your existing ones
				["<Esc>"] = { "focus_list", mode = { "n", "i" } },
				["jk"] = { "focus_list", mode = { "n", "i" } },
			},
		},
	},
	sources = {
		explorer = {
			layout = {
				-- keep the preview hidden by default, but show it in the main editor window when toggled
				preview = "main",
				hidden = { "preview" },
			},
		},
	},
	layouts = {
		vertical = {
			config = function(layout)
				local preview_height = custom_vertical_preview_ratio
				local list_height = 1 - preview_height

				if not layout.layout then
					return layout
				end

				for _, section in ipairs(layout.layout) do
					if section.win == "preview" then
						section.height = preview_height
					elseif section.win == "list" then
						section.height = list_height
					end
				end

				return layout
			end,
		},
	},
}
