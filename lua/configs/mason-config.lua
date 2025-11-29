local mason = require("mason")

mason.setup({
  ui = {
      border = "rounded"
    },
    registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    },
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
      "rust-analyzer",
      "marksman",
      "markdownlint-cli2",
      "glow",

      -- !
      "roslyn",
      "rzls",
      -- "csharp-language-server",
      -- "omnisharp",
    }
})
