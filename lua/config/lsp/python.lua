-- Python language server configurations
local M = {}

function M.setup()
  vim.lsp.config("pyright", {
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
    settings = {
      args = {},
    },
  })
end

return M
