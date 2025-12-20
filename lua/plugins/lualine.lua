return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
		"nvim-tree/nvim-web-devicons",
  "yavorski/lualine-macro-recording.nvim",
	},
  event = "VeryLazy",
  opts = function()
    -- Use a fixed dark theme so the center section does not pick up light grey
    -- highlights from other plugins (e.g. snacks dashboard).
    local theme = "onedark"

    return {
      options = {
        theme = theme,
        component_separators = "",
        section_separators = "",
        globalstatus = true,
        disabled_filetypes = { statusline = { "alpha", "starter", "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 1 }, { "macro_recording", "%S" } },
        lualine_x = { "diagnostics", "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "quickfix", "lazy", "man" },
    }
  end,
}
