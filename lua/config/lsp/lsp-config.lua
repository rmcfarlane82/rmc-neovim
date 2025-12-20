-- Custom LSP server wiring (ts_ls, jsonls, eslint, emmet, etc.) on top of NvChad defaults
local ok_lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
	vim.notify("nvim-lspconfig is not available", vim.log.levels.ERROR)
	return
end

vim.lsp.handlers["textDocument/signatureHelp"] = function() end

local capabilities = require("config.lsp.capabilities").capabilities

local server_modules = {
	"config.lsp.ts_ls",
	"config.lsp.jsonls",
	"config.lsp.eslint",
	"config.lsp.emmet",
	"config.lsp.roslyn",
	"config.lsp.python",
	"config.lsp.lua_ls",
}

for _, module in ipairs(server_modules) do
	local ok, mod = pcall(require, module)
	if ok and type(mod.setup) == "function" then
		mod.setup()
	else
		vim.notify(string.format("Failed to load LSP module: %s", module), vim.log.levels.WARN)
	end
end

local default_servers = {
	"html",
	"cssls",
	"marksman",
}

for _, server in ipairs(default_servers) do
	vim.lsp.config(server, { capabilities = capabilities })
end

local servers = vim.list_extend(vim.deepcopy(default_servers), {
	"ts_ls",
	"jsonls",
	"eslint",
	"emmet_language_server",
	"pyright",
	"basedpyright",
	"ruff_lsp",
	"lua_ls",
})
vim.lsp.enable(servers)

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})


-- Built-in signature help: auto show + overload cycling
--vim.api.nvim_create_autocmd("LspAttach", {
--	callback = function(args)
--		local bufnr = args.buf
--		local client = vim.lsp.get_client_by_id(args.data.client_id)
--		if not client or not client.server_capabilities.signatureHelpProvider then
--			return
--		end
--
--		-- 1) Overload cycling (Neovim 0.11+)
--		vim.keymap.set(
--			{ "i", "n", "s" },
--			"<C-s>",
--			function()
--				vim.lsp.buf.signature_help()
--			end,
--			{ buffer = bufnr, silent = true, desc = "LSP signature / overloads" }
--		)
--
--		-- 2) Auto-show signature when typing '(' or ','
--		vim.api.nvim_create_autocmd("InsertCharPre", {
--			buffer = bufnr,
--			callback = function()
--				local ch = vim.v.char
--				if ch == "(" or ch == "," then
--					-- small defer so the buffer text is updated first
--					vim.defer_fn(function()
--						if vim.api.nvim_get_mode().mode:match("[iR]") then
--							pcall(vim.lsp.buf.signature_help)
--						end
--					end, 0)
--				end
--			end,
--		})
--	end,
--})
-- read :h vim.lsp.config for changing options of lsp servers
