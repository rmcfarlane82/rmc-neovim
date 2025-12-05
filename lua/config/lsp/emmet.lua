-- Emmet language server setup for JSX/HTML authoring
local M = {}

function M.setup()
  vim.lsp.config("emmet_language_server", {
    filetypes = {
      "html",
      "css",
      "scss",
      "javascriptreact",
      "typescriptreact",
      "javascript.jsx",
      "typescript.tsx",
    },
    init_options = {
      html = {
        options = {
          ["bem.enabled"] = true,
        },
      },
    },
  })
end

return M
