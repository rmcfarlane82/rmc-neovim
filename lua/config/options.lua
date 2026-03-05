-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
require("config.lsp")

if vim.fn.exists("+winborder") == 1 then
  vim.o.winborder = "rounded"
end

vim.opt.spelllang = "en_gb"
vim.opt.spelloptions = "camel,noplainbuffer"
vim.opt.scrolloff = 999
vim.opt.wrap = false
vim.opt.relativenumber = false

vim.opt.guicursor = "n-v:block-Cursor,i-c-ci-ve:ver25-iCursor-blinkwait0-blinkoff1-blinkon1,r-cr-o:hor20-rCursor,t:ver25-iCursor-blinkwait0-blinkoff1-blinkon1"
vim.opt.startofline = false
vim.opt.spell = true
