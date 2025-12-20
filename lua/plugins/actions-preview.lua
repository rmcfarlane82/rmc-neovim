return {
  "aznhe21/actions-preview.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    require("actions-preview").setup({
      -- force Snacks as the backend so it looks like your other pickers
      backend = { "snacks" },

      snacks = {
        -- you can tweak this layout later; this is a simple default
        layout = { preset = "default" },
      },

      -- optional: tweak diff context etc
      diff = {
        ctxlen = 3,
      },
    })
  end,
}
