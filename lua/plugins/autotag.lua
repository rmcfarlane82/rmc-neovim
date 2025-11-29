return {
  "windwp/nvim-ts-autotag",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = {
    "html",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "tsx",
    "jsx",
  },
  config = function()
    require("nvim-ts-autotag").setup {
      skip_tags = { "template" },
    }
  end,
}
