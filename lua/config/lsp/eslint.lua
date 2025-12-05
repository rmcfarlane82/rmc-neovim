-- ESLint LSP tweaks (only diagnostics/fix, no formatting)
local M = {}

function M.setup()
  vim.lsp.config("eslint", {
    settings = {
      workingDirectories = { mode = "auto" },
      format = false,
    },
  })
end

return M
