return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true,
    fast_wrap = {
      map = "<M-e>",
      keys = "qwertyuiopzxcvbnmasdfghjkl",
      offset = 0,
    },
  },
  config = function(_, opts)
    local autopairs = require "nvim-autopairs"
    autopairs.setup(opts)

    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
}
