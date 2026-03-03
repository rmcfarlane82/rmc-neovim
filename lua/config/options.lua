-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.api.nvim_command("hi Normal guibg=none ctermbg=none")

vim.diagnostic.config({
  float = { border = "rounded" },
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

if vim.fn.exists("+winborder") == 1 then
  vim.o.winborder = "rounded"
end

do
  local open_floating_preview = vim.lsp.util.open_floating_preview
  ---@diagnostic disable-next-line: duplicate-set-field
  function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    return open_floating_preview(contents, syntax, opts, ...)
  end
end

vim.opt.spelllang = "en_gb"
vim.opt.spelloptions = "camel,noplainbuffer"
vim.opt.scrolloff = 999

vim.opt.guicursor =
  "n-v:block-Cursor,i-c-ci-ve:ver25-iCursor-blinkwait0-blinkoff1-blinkon1,r-cr-o:hor20-rCursor,t:ver25-iCursor-blinkwait0-blinkoff1-blinkon1"
