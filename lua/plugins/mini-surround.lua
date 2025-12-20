return {
  "nvim-mini/mini.surround",
  version = "*",
  event = "VeryLazy",
  opts = {
    -- Use custom mappings so nothing else steals `s`
    mappings = {
      add = "<leader>sa",            -- Add surrounding
      delete = "<leader>sd",         -- Delete surrounding
      replace = "<leader>sr",        -- Replace surrounding
      find = "<leader>sf",           -- Find right surrounding
      find_left = "<leader>sF",      -- Find left surrounding
      highlight = "<leader>sh",      -- Highlight surrounding
      update_n_lines = "<leader>sn", -- Update search range
      suffix_last = "l",      -- Suffix for last
      suffix_next = "n",      -- Suffix for next
    },
  },
  config = function(_, opts)
    require("mini.surround").setup(opts)
  end,
}
