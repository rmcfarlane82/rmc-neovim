return {
	"eero-lehtinen/oklch-color-picker.nvim",
	event = "VeryLazy",
	version = "*",
	keys = {
		-- One handed keymap recommended, you will be using the mouse
		{
			"<leader>C",
			function() require("oklch-color-picker").pick_under_cursor() end,
			desc = "Color picker",
		},
	},
	---@type oklch.Opts
	opts = {
		highlight = {
			-- Options: 'background'|'foreground'|'virtual_left'|'virtual_eol'|'foreground+virtual_left'|'foreground+virtual_eol'
			style = "virtual_left",
		},
	},
}
