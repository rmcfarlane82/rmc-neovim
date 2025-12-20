local opt = vim.opt

opt.timeout = true
opt.timeoutlen = 100
opt.ttimeout = true
opt.ttimeoutlen = 10
opt.updatetime = 200
opt.number = true
opt.relativenumber = true
opt.fillchars = { eob = " " }
opt.winborder = "rounded"
opt.cursorlineopt ='both' -- to enable cursorline!
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.wrap = false
opt.cmdheight = 0
opt.ignorecase = true -- make searches (and flash.nvim) case-insensitive
opt.smartcase = true -- keep capitals meaningful when searching
opt.autoread = true
opt.guicursor = "n-v-c:block,i-ci:ver25,t:ver25"
opt.clipboard = "unnamedplus"


vim.cmd [[autocmd FocusGained,BufEnter * checktime]]

local indent_group = vim.api.nvim_create_augroup("CustomIndent", { clear = true })

local function set_indent(patterns, size)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = patterns,
    group = indent_group,
    callback = function()
      vim.opt_local.shiftwidth = size
      vim.opt_local.tabstop = size
      vim.opt_local.softtabstop = size
    end,
  })
end

set_indent({ "lua", "typescript", "typescriptreact" }, 2)
set_indent({ "cs", "csharp" }, 4)

