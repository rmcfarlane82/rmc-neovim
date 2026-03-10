local M = {}

local function apply_markdown_highlights()
  local groups = {
    "RenderMarkdownCode",
    "RenderMarkdownCodeInline",
    "RenderMarkdownH1Bg",
    "RenderMarkdownH2Bg",
    "RenderMarkdownH3Bg",
    "RenderMarkdownH4Bg",
    "RenderMarkdownH5Bg",
    "RenderMarkdownH6Bg",
  }
  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      hl.bg = nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

local function apply_core_highlights()
  vim.api.nvim_set_hl(0, "Visual", { bg = "#89b4fa", fg = "#1e1e2e" })

  -- Map Delta Catppuccin Mocha colors to Neovim diff highlights
  vim.api.nvim_set_hl(0, "DiffAdd", { fg = "#cdd6f4", bg = "#394545" }) -- plus-style
  vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#cdd6f4", bg = "#493447" }) -- minus-style
  vim.api.nvim_set_hl(0, "DiffChange", { fg = "none", bg = "none" }) -- base + subtle tint
  vim.api.nvim_set_hl(0, "DiffText", { fg = "#cdd6f4", bg = "#694559", bold = true }) -- minus-emph-style

  -- Lualine normal mode color
  vim.schedule(function()
    vim.api.nvim_set_hl(0, "lualine_a_normal", { fg = "#1a1a1a", bg = "#E5E510" })
  end)

  -- Cursor colors: yellow in normal mode, green in insert
  vim.api.nvim_set_hl(0, "Cursor",  { fg = "#1a1a1a", bg = "#E5E510" })
  vim.api.nvim_set_hl(0, "iCursor", { fg = "#1a1a1a", bg = "#ffffff" })

  -- Optional: Line number colors
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#6c7086" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#a6adc8", bold = true })
end

function M.apply()
  vim.api.nvim_command("hi Normal guibg=none ctermbg=none")
  apply_markdown_highlights()
  apply_core_highlights()
end

return M
