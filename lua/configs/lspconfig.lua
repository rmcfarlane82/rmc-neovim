local ok_lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
  vim.notify("nvim-lspconfig is not available", vim.log.levels.ERROR)
  return
end

require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("ts_ls", {
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  settings = {
    typescript = {
      format = { enable = false },
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      format = { enable = false },
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})

local ok_schemastore, schemastore = pcall(require, "schemastore")
local schema_list = {}
if ok_schemastore then
  schema_list = schemastore.json.schemas()
end

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = vim.tbl_deep_extend(
        "force",
        {},
        schema_list,
        { { name = "package.json", fileMatch = { "package.json" } } }
      ),
      validate = { enable = true },
    },
  },
})

vim.lsp.config("eslint", {
  settings = {
    workingDirectories = { mode = "auto" },
    format = false,
  },
})

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

vim.lsp.config("roslyn", {
  
})

local servers = {
  "html",
  "cssls",
  "marksman",
  "ts_ls",
  "jsonls",
  "eslint",
  "emmet_language_server",
}
vim.lsp.enable(servers)

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
-- read :h vim.lsp.config for changing options of lsp servers 
