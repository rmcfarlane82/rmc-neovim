-- PowerShell Editor Services (powershell_es) configuration
local capabilities = require("config.lsp.capabilities").capabilities
local M = {}

function M.setup()
  local shell = vim.fn.exepath("pwsh") ~= "" and "pwsh" or "powershell.exe"

  vim.lsp.config("powershell_es", {
    capabilities = capabilities,
    bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
    shell = shell,
    filetypes = { "ps1", "psm1", "psd1" },
  })
end

return M
