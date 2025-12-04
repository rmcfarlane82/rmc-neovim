-- General Neovim options layered on NvChad defaults
require "nvchad.options"

-- add yours here!

local o = vim.opt

o.autoread = true
vim.cmd [[autocmd FocusGained,BufEnter * checktime]]

o.cursorlineopt ='both' -- to enable cursorline!
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true
o.wrap = false
--o.guicursor = table.concat({
--  "n-v-c:block-Cursor", -- normal/visual/command: block uses Cursor highlight
--  "i-ci-ve:ver25-lCursor", -- insert/cmd-line insert: vertical bar w/ lCursor colors
--  "t:ver25-lCursor", -- terminal-mode cursor matches insert colors
--  "r-cr:hor20-Cursor", -- replace modes: horizontal bar
--  "o:hor50-Cursor", -- operator-pending
--  "sm:block-blinkwait175-blinkoff150-blinkon175-Cursor", -- showmatch
--}, ",")
--o.equalalways = true
--o.eadirection = "both"
o.winminwidth=10
o.winminheight=0
o.splitkeep="screen"
