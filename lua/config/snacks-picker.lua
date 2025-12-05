local custom_vertical_preview_ratio = 0.75

return {
  enabled = true,
  win = {
    input = {
      keys = {
        ["<Esc>"] = { "focus_list", mode = { "n", "i" } },
        ["jk"] = {
          "focus_list",
          mode = { "n", "i" },
        },
      },
    },
    preview = {
      keys = {
        H = "preview_scroll_left",
        J = "preview_scroll_down",
        K = "preview_scroll_up",
        L = "preview_scroll_right",
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
