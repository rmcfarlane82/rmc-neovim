-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.api.nvim_command("hi Normal guibg=none ctermbg=none")

vim.diagnostic.config({
  float = { border = "rounded" },
})

vim.opt.spelllang = "en_gb"
vim.opt.scrolloff = 999

vim.opt.guicursor =
  "n-v:block-Cursor,i-c-ci-ve:ver25-iCursor-blinkwait0-blinkoff1-blinkon1,r-cr-o:hor20-rCursor,t:ver25-iCursor-blinkwait0-blinkoff1-blinkon1"
