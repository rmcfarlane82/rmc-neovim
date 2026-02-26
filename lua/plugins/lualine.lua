return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"yavorski/lualine-macro-recording.nvim",
	},
	opts = function()

		local theme = "codedark"

		return {
			options = {
				theme = theme,
				component_separators = "",
				section_separators = "",
				globalstatus = true,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					"branch",
					"diff",
				 },
				lualine_c = {
					{ "filename",        path = 1 },
					{ "macro_recording", "%S" },
				},
				lualine_x = {
					{ "diagnostics" },
					{ "encoding" },
					{ "fileformat" },
					{ "filetype" },
					{ "lsp_status" },
					{ "datetime", style = "📅 %a %d %b 🕧 %H:%M" },
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			extensions = { "quickfix", "lazy", "man" },
		}
	end,
}
