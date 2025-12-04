local widths = {}
local data_file = vim.fn.stdpath("data") .. "/neotree_widths.lua"

local function get_project_root()
  -- Keep it simple: stdpath data per cwd is enough for per-project width
  return vim.loop.cwd() or vim.fn.getcwd()
end

local function load_widths()
  local ok, tbl = pcall(dofile, data_file)
  if ok and type(tbl) == "table" then
    widths = tbl
  else
    widths = {}
  end
end

local function persist_widths()
  local ok, inspect = pcall(require, "vim.inspect")
  if not ok then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(data_file, ":h"), "p")
  local lua_string = "return " .. inspect(widths)
  vim.fn.writefile(vim.split(lua_string, "\n"), data_file)
end

local function store_width(width)
  if type(width) ~= "number" then
    return
  end
  local root = get_project_root()
  if not root or widths[root] == width then
    return
  end
  widths[root] = width
  persist_widths()
end

local function record_width_from_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not bufnr or vim.bo[bufnr].filetype ~= "neo-tree" then
    return
  end
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local width = vim.api.nvim_win_get_width(win)
  store_width(width)
end

local function apply_saved_width(win)
  local root = get_project_root()
  local width = widths[root]
  if type(width) ~= "number" then
    return
  end
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  -- Schedule to avoid fighting with Neo-tree's own initial resize
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_width, win, width)
    end
  end)
end

load_widths()

-- When we enter a Neo-tree window, restore saved width for this project
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].filetype ~= "neo-tree" then
      return
    end
    apply_saved_width(vim.api.nvim_get_current_win())
  end,
})

-- Remember width when leaving the Neo-tree window so we persist the latest resize
vim.api.nvim_create_autocmd("WinLeave", {
  pattern = "*",
  callback = function(args)
    record_width_from_buf(args.buf)
  end,
})

-- If we exit Neovim while focused on Neo-tree capture the width as well
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        store_width(vim.api.nvim_win_get_width(win))
        break
      end
    end
  end,
})
