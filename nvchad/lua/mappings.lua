---------------------------------------------------------------------------
-- NvChad Default Mappings
---------------------------------------------------------------------------
-- require "nvchad.mappings"

---------------------------------------------------------------------------
-- Basic Setup
---------------------------------------------------------------------------
local map = vim.keymap.set

-- Define DAP breakpoint icon (red emoji dot)
vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })

-- Close the current buffer without collapsing back to Neo-tree
local function close_buffer_keep_window()
  local current = vim.api.nvim_get_current_buf()
  local listed = vim.fn.getbufinfo { buflisted = 1 }

  local function is_valid(buf)
    return buf and buf > 0
      and buf ~= current
      and vim.api.nvim_buf_is_valid(buf)
      and vim.fn.buflisted(buf) == 1
      and vim.bo[buf].filetype ~= "neo-tree"
  end

  local function open_scratch()
    vim.cmd.enew()
    local scratch = vim.api.nvim_get_current_buf()
    vim.bo[scratch].bufhidden = "wipe"
    vim.bo[scratch].buflisted = false
    vim.bo[scratch].swapfile = false
    vim.bo[scratch].buftype = vim.bo[current].buftype ~= "" and vim.bo[current].buftype or ""
  end

  if #listed < 2 then
    open_scratch()
    vim.cmd("bdelete " .. current)
    return
  end

  local target = vim.fn.bufnr "#"
  if not is_valid(target) then
    target = nil
    for _, buf in ipairs(listed) do
      if is_valid(buf.bufnr) then
        target = buf.bufnr
        break
      end
    end
  end

  if not target then
    open_scratch()
  else
    vim.cmd("buffer " .. target)
  end

  if vim.api.nvim_buf_is_valid(current) then
    vim.cmd("bdelete " .. current)
  end
end

---------------------------------------------------------------------------
-- Terminal helpers (NVChad term wrapper)
---------------------------------------------------------------------------
local ok_nvterm, nvterm = pcall(require, "nvchad.term")

if ok_nvterm then
  -- Toggle dedicated horizontal / vertical terminals with Alt+h / Alt+v
  map({ "n", "t" }, "<A-h>", function()
    nvterm.toggle { pos = "sp", id = "htoggleTerm" }
  end, { desc = "Terminal: Toggle horizontal terminal" })

  map({ "n", "t" }, "<A-v>", function()
    nvterm.toggle { pos = "vsp", id = "vtoggleTerm" }
  end, { desc = "Terminal: Toggle vertical terminal" })
end

---------------------------------------------------------------------------
-- General Keymaps
---------------------------------------------------------------------------
-- Enter command mode quickly
map("n", ";", ":", { desc = "Enter command mode" })

-- Exit insert mode using 'jk'
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Reload keymap definitions without re-sourcing all of init.lua
map("n", "<leader>R", function()
  local mappings_path = vim.fn.stdpath("config") .. "/lua/mappings.lua"
  dofile(mappings_path)
  vim.notify("Keymaps reloaded", vim.log.levels.INFO, { title = "mappings" })
end, { desc = "Config: Reload keymaps" })

-- Cycle through bufferline tabs with Ctrl+n / Ctrl+p
map("n", "<C-n>", "<cmd>BufferLineCycleNext<CR>", { desc = "Bufferline: Next buffer" })
map("n", "<C-p>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Bufferline: Previous buffer" })
map("n", "<leader>q", close_buffer_keep_window, { desc = "Close current buffer" })

-- Jump straight to the Neo-tree file explorer
map("n", "<C-e>", "<cmd>Neotree focus<CR>", { desc = "Neo-tree: Focus explorer" })

-- Save file (works in all modes)
--map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><ESC>", { desc = "Save file" })

---------------------------------------------------------------------------
-- Terminal Navigation
---------------------------------------------------------------------------
-- Exit terminal mode
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Move between windows from terminal mode
map("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { desc = "Move to left window" })
map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { desc = "Move to below window" })
map("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { desc = "Move to above window" })
map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { desc = "Move to right window" })

---------------------------------------------------------------------------
-- Window Navigation
---------------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Window: Focus left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window: Focus below" })
map("n", "<C-k>", "<C-w>k", { desc = "Window: Focus above" })
map("n", "<C-l>", "<C-w>l", { desc = "Window: Focus right" })

---------------------------------------------------------------------------
-- Window Resizing
---------------------------------------------------------------------------
-- Resize splits (Ctrl + Alt + direction)
map("n", "<C-A-h>", ":vertical resize +2<CR>", { desc = "Expand vertical split" })
map("n", "<C-A-l>", ":vertical resize -2<CR>", { desc = "Shrink vertical split" })
map("n", "<C-A-j>", ":resize +2<CR>", { desc = "Expand horizontal split" })
map("n", "<C-A-k>", ":resize -2<CR>", { desc = "Shrink horizontal split" })

---------------------------------------------------------------------------
-- Telescope & LSP
---------------------------------------------------------------------------
-- File search utilities
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Telescope: Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Telescope: Grep files" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Telescope: Recent files" })

-- Go to implementation
map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", { desc = "Go to implementation (Telescope)" })

-- Code actions (two styles: Telescope + native LSP)
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
map("n", "<leader>.", vim.lsp.buf.code_action, { desc = "Code actions" })

---------------------------------------------------------------------------
-- .NET Utilities
---------------------------------------------------------------------------
map("n", "<leader>cr", function()
  require("dotnet_runner").pick_and_run()
end, { desc = "dotnet: run project" })
map("n", "<leader>ct", function()
  require("dotnet_runner").pick_and_test()
end, { desc = "dotnet: test project" })
map("n", "<leader>cd", function()
  require("dotnet_runner").pick_and_debug()
end, { desc = "dotnet: debug project" })

---------------------------------------------------------------------------
-- Debugging (DAP) — For project / application debugging
---------------------------------------------------------------------------
local dap = require "dap"
local dapui = require "dapui"

-- Core DAP controls
map("n", "<F5>", dap.continue, { desc = "DAP: Start / Continue debugging" })
map("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
map("n", "<F10>", dap.step_over, { desc = "DAP: Step over" })
map("n", "<F11>", dap.step_into, { desc = "DAP: Step into" })
map("n", "<S-F11>", dap.step_out, { desc = "DAP: Step out" })

-- DAP session utilities
map("n", "<leader>dr", dap.repl.open, { desc = "DAP: Open REPL" })
map("n", "<leader>dl", dap.run_last, { desc = "DAP: Run last session" })

-- DAP UI controls
map("n", "<leader>du", dapui.toggle, { desc = "DAP UI: Toggle panels" })
map("n", "<leader>de", dapui.eval, { desc = "DAP UI: Evaluate expression" })
map("n", "<leader>dq", function()
  dapui.close {}
end, { desc = "DAP UI: Close all debug windows" })

---------------------------------------------------------------------------
-- Testing (Neotest) — For running & debugging tests
---------------------------------------------------------------------------
local neotest = require "neotest"

-- Run nearest test
map("n", "<leader>tn", function()
  neotest.run.run()
end, { desc = "Test: Run nearest test" })

-- Run all tests in current file
map("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand "%")
end, { desc = "Test: Run all tests in current file" })

-- Run all tests in current project
map("n", "<leader>ta", function()
  neotest.run.run { suite = true }
end, { desc = "Test: Run all tests in project" })

-- Debug nearest test using DAP
map("n", "<leader>td", function()
  neotest.run.run { strategy = "dap" }
end, { desc = "Test: Debug nearest test (DAP)" })

-- Stop currently running tests
map("n", "<leader>ts", neotest.run.stop, { desc = "Test: Stop running tests" })

-- Rerun last suite
map("n", "<leader>tl", function()
  neotest.run.run_last()
end, { desc = "Test: Rerun last test suite" })

-- Test summary / results panels
map("n", "<leader>to", neotest.summary.toggle, { desc = "Test: Toggle summary panel" })
map("n", "<leader>tp", neotest.output_panel.toggle, { desc = "Test: Toggle output panel" })

-- Diagnostics
map("n", "ge", vim.diagnostic.open_float, { desc = "Open Error" })
map("n", "[d", vim.diagnostic.get_prev, { desc = "Prev Error" })
map("n", "]d", vim.diagnostic.get_next, { desc = "Next Error" })

-- GIT
map("n", "<leader>gf", "<cmd>Telescope git_files<CR>", { desc = "Git files" })
map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Git status" })

map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Git commits" })
map("n", "<leader>gC", "<cmd>Telescope git_bcommits<CR>", { desc = "Buffer commits" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", { desc = "Git branches" })
map("n", "<leader>gS", "<cmd>Telescope git_stash<CR>", { desc = "Git stash" })
