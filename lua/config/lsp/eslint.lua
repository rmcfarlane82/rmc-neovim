-- ESLint LSP tweaks (only diagnostics/fix, no formatting)
local capabilities = require("config.lsp.capabilities").capabilities
local M = {}

function M.setup()
  vim.lsp.config("eslint", {
    capabilities = capabilities,
    settings = {
      workingDirectories = { mode = "auto" },
      format = false,
    },
  })
end

return M
