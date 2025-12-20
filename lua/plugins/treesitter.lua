return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",  -- install/update parsers when you run :Lazy sync

  event = { "BufReadPost", "BufNewFile" },

  opts = {
    ensure_installed = {
      "vim",
      "lua",
      "vimdoc",
      "html",
      "css",
      "javascript",
      "typescript",
      "tsx",
      "json",
      "jsonc",
      "python",
      "markdown",
      "markdown_inline",
			"diff",

      "c_sharp",
      "razor",
    },

    highlight = {
      enable = true,
    },
  },

  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
