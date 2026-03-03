return {

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.layouts = opts.picker.layouts or {}
      opts.picker.layouts.ivy = { layout = { height = 0.5 } }

      opts.picker.win = opts.picker.win or {}
      opts.picker.win.input = opts.picker.win.input or {}
      opts.picker.win.input.keys = opts.picker.win.input.keys or {}
      opts.picker.win.input.keys["<C-u>"] = { "preview_scroll_up", mode = { "n", "i" } }
      opts.picker.win.input.keys["<C-d>"] = { "preview_scroll_down", mode = { "n", "i" } }

      opts.picker.sources.files = opts.picker.sources.files or {}
      opts.picker.sources.files.layout = { preset = "ivy" }

      opts.picker.sources.grep = opts.picker.sources.grep or {}
      opts.picker.sources.grep.layout = { preset = "ivy" }

      opts.picker.sources.explorer = opts.picker.sources.explorer or {}
      opts.picker.sources.explorer.win = opts.picker.sources.explorer.win or {}
      opts.picker.sources.explorer.win.input = opts.picker.sources.explorer.win.input or {}
      opts.picker.sources.explorer.win.input.keys = opts.picker.sources.explorer.win.input.keys or {}

      opts.picker.sources.explorer.win.input.keys["jk"] = { "focus_list", mode = { "n", "i" } }

      opts.picker.sources.explorer.layout = {
        preview = "main",
        hidden = { "preview" },
      }

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.keys = opts.dashboard.preset.keys or {}
      table.insert(opts.dashboard.preset.keys, {
        key = "m",
        icon = "",
        desc = "Mason",
        action = ":Mason",
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        border = "thin",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
      },
    },
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
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "max397574/better-escape.nvim",
    config = function()
      require("better_escape").setup()
    end,
  },
}
