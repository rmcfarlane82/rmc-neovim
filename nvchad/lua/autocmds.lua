require "nvchad.autocmds"
if vim.loop.os_uname().version:match("Windows") then
  vim.opt.shell = "pwsh.exe"                     -- or "powershell.exe"
  vim.opt.shellcmdflag =
    "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- Use your Windows Terminal scheme (Campbell shown here).
-- Replace the hexes if you use another scheme.
local p = {
  [0]  = "#0C0C0C",  -- black
  [1]  = "#C50F1F",  -- red
  [2]  = "#13A10E",  -- green
  [3]  = "#C19C00",  -- yellow
  [4]  = "#0037DA",  -- blue
  [5]  = "#881798",  -- magenta
  [6]  = "#3A96DD",  -- cyan
  [7]  = "#CCCCCC",  -- white
  [8]  = "#767676",  -- brBlack
  [9]  = "#E74856",  -- brRed
  [10] = "#16C60C",  -- brGreen
  [11] = "#F9F1A5",  -- brYellow
  [12] = "#3B78FF",  -- brBlue
  [13] = "#B4009E",  -- brMagenta
  [14] = "#61D6D6",  -- brCyan
  [15] = "#F2F2F2",  -- brWhite
}

local function set_term_colors()
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = p[i]
  end
end

-- Ensure truecolor and reapply after any theme change
vim.opt.termguicolors = true
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, { callback = set_term_colors })
vim.api.nvim_create_autocmd("TermOpen", { callback = set_term_colors })

set_term_colors()

--vim.api.nvim_create_autocmd("BufDelete", {
--  callback = function()
--    local bufs = vim.t.bufs
--    if #bufs == 1 and vim.api.nvim_buf_get_name(bufs[1]) == "" then
--      vim.cmd "Nvdash"
--    end
--  end,
--})
