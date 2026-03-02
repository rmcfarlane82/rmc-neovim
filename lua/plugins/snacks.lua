return {

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = opts.picker.sources.explorer or {}
      opts.picker.sources.explorer.win = opts.picker.sources.explorer.win or {}
      opts.picker.sources.explorer.win.input = opts.picker.sources.explorer.win.input or {}
      opts.picker.sources.explorer.win.input.keys = opts.picker.sources.explorer.win.input.keys or {}

      opts.picker.sources.explorer.win.input.keys["jk"] = { "focus_list", mode = { "n", "i" } }
    end,
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
