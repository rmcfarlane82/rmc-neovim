local M = {}

local base = vim.lsp.protocol.make_client_capabilities()

local ok, blink = pcall(require, "blink.cmp")
if ok and blink.get_lsp_capabilities then
  M.capabilities = blink.get_lsp_capabilities(base)
else
  M.capabilities = base
end

return M
