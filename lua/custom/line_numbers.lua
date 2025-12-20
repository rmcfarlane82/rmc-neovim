local Snacks = require("snacks")

local M = {}

local line_number_modes = { "relative", "absolute", "off" }
local state_file = vim.fn.stdpath("state") .. "/line_number_mode"
local current_mode ---@type string?

local function save_mode(mode)
  local dir = vim.fn.fnamemodify(state_file, ":h")
  if dir ~= "" then
    vim.fn.mkdir(dir, "p")
  end
  pcall(vim.fn.writefile, { mode }, state_file)
end

local function should_apply(win)
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local bt = vim.bo[buf].buftype
  return not (bt == "nofile" or bt == "prompt")
end

local function apply_to_windows(mode)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local opts = { scope = "local", win = win }
    if should_apply(win) then
      if mode == "relative" then
        vim.api.nvim_set_option_value("number", true, opts)
        vim.api.nvim_set_option_value("relativenumber", true, opts)
      elseif mode == "absolute" then
        vim.api.nvim_set_option_value("number", true, opts)
        vim.api.nvim_set_option_value("relativenumber", false, opts)
      else
        vim.api.nvim_set_option_value("number", false, opts)
        vim.api.nvim_set_option_value("relativenumber", false, opts)
      end
    else
      vim.api.nvim_set_option_value("number", false, opts)
      vim.api.nvim_set_option_value("relativenumber", false, opts)
    end
  end
end

local function set_mode(mode, opts)
  opts = opts or {}
  current_mode = mode
  if mode == "relative" then
    vim.opt.number = true
    vim.opt.relativenumber = true
  elseif mode == "absolute" then
    vim.opt.number = true
    vim.opt.relativenumber = false
  else
    vim.opt.number = false
    vim.opt.relativenumber = false
  end
  apply_to_windows(mode)
  save_mode(mode)
  if not opts.silent then
    Snacks.notify(("Line numbers: %s"):format(mode), { title = "Line Numbers" })
  end
end

local function get_mode()
  if vim.opt_local.number:get() and vim.opt_local.relativenumber:get() then
    return "relative"
  elseif vim.opt_local.number:get() then
    return "absolute"
  else
    return "off"
  end
end

local function load_mode()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  if ok and lines[1] then
    for _, mode in ipairs(line_number_modes) do
      if mode == lines[1] then
        set_mode(mode, { silent = true })
        return
      end
    end
  end
  set_mode(line_number_modes[1], { silent = true })
end

function M.cycle()
  local current = get_mode()
  local next_index = 1
  for i, mode in ipairs(line_number_modes) do
    if mode == current then
      next_index = (i % #line_number_modes) + 1
      break
    end
  end
  set_mode(line_number_modes[next_index])
end

function M.setup()
  if M._initialized then
    return
  end
  load_mode()
  vim.api.nvim_create_autocmd("WinNew", {
    group = vim.api.nvim_create_augroup("custom_line_numbers", { clear = true }),
    callback = function()
      if current_mode then
        apply_to_windows(current_mode)
      end
    end,
  })
  M._initialized = true
end

return M
