-- JSON language server configuration with SchemaStore integration
local capabilities = require("config.lsp.capabilities").capabilities
local M = {}

function M.setup()
  local ok_schemastore, schemastore = pcall(require, "schemastore")
  local package_schema = {
    name = "package.json",
    fileMatch = { "package.json" },
    url = "https://json.schemastore.org/package.json",
  }
  local schema_list = {}

  if ok_schemastore then
    schema_list = schemastore.json.schemas()

    local has_package_schema = false
    for _, schema in ipairs(schema_list) do
      if schema.name == package_schema.name then
        has_package_schema = true
        break
      end
    end

    if not has_package_schema then
      table.insert(schema_list, package_schema)
    end
  else
    schema_list = { package_schema }
  end

  vim.lsp.config("jsonls", {
    capabilities = capabilities,
    settings = {
      json = {
        schemas = schema_list,
        validate = { enable = true },
      },
    },
  })
end

return M
