-- lua/plugins/noice-cmdline.lua
return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = { "MunifTanjim/nui.nvim" },   -- no notify dependency needed
	opts = {
		cmdline = {
			enabled = true,
			view = "cmdline_popup",
			format = { cmdline = { pattern = "^:", icon = "", lang = "vim" } },
		},
		messages = { enabled = false },
		notify = { enabled = false },
		lsp = {
			enabled = true,
			progress = { enabled = false },
			signature = { enabled = false },
			hover = {
				enabled = true,
				view = "lsp_hover",
			},
			documentation = { view = "lsp_hover" },
		},
		presets = {
			command_palette = true,
			lsp_doc_border = true,
		},
		views = {
			cmdline_popup = {
				position = { row = "30%", col = "50%" },
				size = { width = 60, height = "auto" },
				border = { style = "rounded" },
			},
			lsp_hover = {
				view = "hover",
				border = { style = "rounded", padding = { 0, 1 } },
				close = {
					events = { "BufLeave" },
					keys = { "q", "<Esc>" },
				},
				win_options = {
					wrap = true,
					linebreak = true,
					winhighlight = {
						Normal = "BlinkCmpDoc",
						FloatBorder = "BlinkCmpDocBorder",
						CursorLine = "BlinkCmpDocCursorLine",
					},
				},
			},
		},
	},
}
