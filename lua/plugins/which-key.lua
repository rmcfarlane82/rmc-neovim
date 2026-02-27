return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
		preset = "helix",
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
    },
    -- Limit triggers so jk escape mappings don't summon which-key
    triggers = {
      { "<auto>", mode = { "n", "v", "o" } },
    },
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>", group = "Leader" },
        { "<leader>u", group = "Toggle" },
        { "<leader>g", group = "Git" },
        { "<leader>s", group = "Surround" },
        { "<leader>f", group = "Find" },
        { "<leader>b", group = "Buffer" },
        { "<leader>l", group = "LSP" },
        { "<leader>t", group = "Test" },
      },
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
  end,
}
