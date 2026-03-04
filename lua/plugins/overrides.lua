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

      local img = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("config"), "screenshots", "nvim-vs-code.png"))
      opts.dashboard.sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
        {
          section = "terminal",
          pane = 2,
          padding = 1,
          cmd = "ipconfig",
          height = 8,
          gap = 1,
        },
        {
          section = "terminal",
          pane = 2,
          align = "center",
          cmd = {
            "chafa",
            img,
            "--format",
            "symbols",
            "--size",
            "60x22",
            "--stretch",
            "-w",
            "9",
            "--dither",
            "ordered",
          },
          height = 21,
          padding = 1,
        },
      }
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
}
