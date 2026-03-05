-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
local highlights = require("config.highlights")

-- Apply once on start-up, and again after any :colorscheme changes (ColorScheme autocmd below).
highlights.apply()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    highlights.apply()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "nofile" then
      return
    end
    local ok, cfg = pcall(vim.api.nvim_win_get_config, 0)
    if not ok or cfg.relative == "" then
      return
    end
    vim.keymap.set("n", "<Esc>", function()
      pcall(vim.api.nvim_win_close, 0, true)
    end, { buffer = args.buf, silent = true })
  end,
})
