-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
---- Make floating windows transparent (and keep it after :colorscheme changes)
local function apply_transparency()
  -- Core UI
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e1e1e" }) -- terminal-like float
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#45475a" })

  -- Snacks terminal window
  vim.api.nvim_set_hl(0, "SnacksTerminal", { bg = "#1e1e1e" })

  -- Remove backdrop dimming
  vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = "NONE" })

  --------------------------------------------------
  -- Snacks Picker / Explorer transparency
  --------------------------------------------------

  -- make picker panels inherit Normal background
  vim.api.nvim_set_hl(0, "SnacksPicker", { link = "Normal" })
  vim.api.nvim_set_hl(0, "SnacksPickerList", { link = "Normal" })
  vim.api.nvim_set_hl(0, "SnacksPickerPreview", { link = "Normal" })
  vim.api.nvim_set_hl(0, "SnacksPickerInput", { link = "Normal" })
  vim.api.nvim_set_hl(0, "SnacksPickerBox", { link = "Normal" })

  -- border styling (subtle)
  vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#6c7086", bg = "NONE" })

  -- title styling (no block background)
  vim.api.nvim_set_hl(0, "SnacksPickerTitle", {
    fg = "#e6e9ef",
    bg = "NONE",
  })

  -- directory text color
  vim.api.nvim_set_hl(0, "SnacksPickerDirectory", {
    fg = "#f2f2f2",
  })
end

apply_transparency()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_transparency,
})
