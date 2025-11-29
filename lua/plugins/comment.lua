return {
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },
  {
    "numToStr/Comment.nvim",
    opts = function(_, opts)
      local integration_ok, integration = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
      if integration_ok then
        opts = opts or {}
        opts.pre_hook = integration.create_pre_hook()
      end

      return opts
    end,
  },
}
