-- Placeholder Roslyn configuration (extended settings can live here)
local capabilities = require("config.lsp.capabilities").capabilities
local M = {}

function M.setup()
  vim.lsp.config("roslyn", { capabilities = capabilities })
end

return M
