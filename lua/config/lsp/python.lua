-- Python language server configurations
local capabilities = require("config.lsp.capabilities").capabilities
local M = {}

function M.setup()
  vim.lsp.config("pyright", {
    capabilities = capabilities,
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "standard",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "workspace",
        },
      },
    },
  })

  vim.lsp.config("basedpyright", {
    capabilities = capabilities,
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "strict",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
    },
  })

  vim.lsp.config("ruff_lsp", {
    capabilities = capabilities,
    settings = {
      args = {},
    },
  })
end

return M
