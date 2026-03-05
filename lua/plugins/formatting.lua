return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        prettier = {
          prepend_args = { "--print-width", "180" },
        },
        prettierd = {
          prepend_args = { "--print-width", "180" },
        },
      },
    },
  },
}
