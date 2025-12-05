return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
    },
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>", group = "leader" },
        { "<leader>u", group = "toggle" },
        { "<leader>g", group = "git" },
        { "<leader>s", group = "search" },
        { "<leader>f", group = "file" },
        { "<leader>b", group = "buffer" },
      },
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
  end,
}
