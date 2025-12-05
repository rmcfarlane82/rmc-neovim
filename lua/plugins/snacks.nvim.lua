local scroll = require("config.snacks-scroll")
local statuscolumn = require("config.status-column")

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    keymap = { enabled = true },
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "focus_list", mode = { "n", "i" } },
            ["jk"] = { "focus_list", mode = { "n", "i" } },
          },
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = scroll,
    statuscolumn = statuscolumn,
    words = { enabled = true },
    terminal = { enabled = true },
    animate = { enabled = true },
    bufdelete = { enabled = true },
    zen = { enabled = true },
  },
}
