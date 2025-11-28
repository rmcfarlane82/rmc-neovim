return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  config = function()
    require("bufferline").setup {
      options = {
        mode = "buffers", -- or "tabs"
        separator_style = "thick", -- "slant", "thick", "thin", "padded_slant"
        show_buffer_close_icons = false,
        show_close_icon = false,
        always_show_bufferline = true,
        diagnostics = "nvim_lsp",
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
          },
        },
      },

      -- 🎨 STYLE / THEMING
      highlights = {
        -- buffer_selected = {
        --   fg = "#ffffff",
        --   bg = "#2D2D30",
        --   italic = false,
        -- },
        -- background = {
        --   fg = "#a6accd",
        --   bg = "#181825",
        -- },
        fill = {
          bg = "#1e1e1e",
          fg = "#1e1e1e",
        },
      },
    }
  end,
}
