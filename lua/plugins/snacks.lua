local explorer_width = 40

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local img = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("config"), "screenshots", "nvim-vs-code.png"))
      opts = vim.tbl_deep_extend("force", opts or {}, {
        scroll = { enabled = true },
        picker = {
          layouts = {
            ivy = { layout = { height = 0.5 } },
          },
          win = {
            input = {
              keys = {
                ["<C-u>"] = { "preview_scroll_up", mode = { "n", "i" } },
                ["<C-d>"] = { "preview_scroll_down", mode = { "n", "i" } },
              },
            },
          },
          sources = {
            files = { layout = { preset = "ivy" } },
            grep = { layout = { preset = "ivy" } },
            explorer = {
              hidden = true,
              ignored = true,
              win = {
                input = {
                  keys = {
                    ["jk"] = { "focus_list", mode = { "n", "i" } },
                  },
                },
              },
              on_close = function(picker)
                local root = picker.layout and picker.layout.root
                if root and root.win and vim.api.nvim_win_is_valid(root.win) then
                  explorer_width = vim.api.nvim_win_get_width(root.win)
                end
              end,
              layout = {
                preview = "main",
                hidden = { "preview" },
                layout = {
                  width = function()
                    return explorer_width
                  end,
                  min_width = 20,
                },
              },
            },
          },
        },
        dashboard = {
          sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "startup" },
          },
        },
      })

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.keys = opts.dashboard.preset.keys or {}
      table.insert(opts.dashboard.preset.keys, {
        key = "m",
        icon = "",
        desc = "Mason",
        action = ":Mason",
      })

      return opts
    end,
  },
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        signature = {
          enabled = false,
          auto_open = {
            enabled = false,
          },
        },
        hover = {
          enabled = false,
        },
      },
      views = {
        hover = {
          border = {
            style = "rounded",
          },
        },
      },
    },
  },
}
