local mason = require("mason")
local mason_tool_installer = require("mason-tool-installer")

mason.setup({
  ui = {
    border = "rounded",
  },
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
})

mason_tool_installer.setup({
  ensure_installed = {
    "lua-language-server",

    "xmlformatter",
    "csharpier",
    "prettier",

    "stylua",
    "bicep-lsp",
    "html-lsp",
    "css-lsp",
    "eslint-lsp",
    "typescript-language-server",
    "emmet-language-server",
    "json-lsp",
    "pyright",
    "basedpyright",
    "ruff",
    "black",
    "isort",
    "rust-analyzer",
    "marksman",
    "markdownlint-cli2",
    "glow",

    -- C#
    "roslyn",
  },

  -- nice defaults
  run_on_start = true,   -- install on startup
  start_delay = 3000,    -- ms delay so it doesn’t block UI
  auto_update = false,   -- or true if you want regular updates
})
