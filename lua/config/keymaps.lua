-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-e>", function()
  require("snacks").explorer()
end, { desc = "Open file explorer" })

-- remove default resize mappings
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

-- add new resize mappings
vim.keymap.set("n", "<C-M-h>", ":vertical resize -2<CR>", { silent = true })
vim.keymap.set("n", "<C-M-l>", ":vertical resize +2<CR>", { silent = true })
vim.keymap.set("n", "<C-M-k>", ":resize +2<CR>", { silent = true })
vim.keymap.set("n", "<C-M-j>", ":resize -2<CR>", { silent = true })
vim.keymap.set("n", "j", "+")
vim.keymap.set("n", "k", "-")

vim.keymap.set("n", "K", function()
  vim.lsp.buf.hover({ border = "rounded" })
end, { desc = "Hover" })

vim.keymap.set("n", "<Esc>", function()
  local closed = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
      closed = true
    end
  end
  if closed then
    return
  end
  vim.cmd("nohlsearch")
end, { desc = "Close floating windows" })

Snacks.toggle({
  name = "Virtual Text",
  get = function()
    return vim.diagnostic.config().virtual_text ~= false
  end,
  set = function(state)
    vim.diagnostic.config({ virtual_text = state })
  end,
}):map("<leader>uv")

Snacks.toggle({
  name = "Typewriter Mode",
  get = function()
    return vim.o.scrolloff >= 999
  end,
  set = function(state)
    vim.o.scrolloff = state and 999 or 4
  end,
}):map("<leader>ut")
