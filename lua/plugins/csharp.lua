return {

  -- Add Crashdummyy's mason registry so `:MasonInstall roslyn` works
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts = vim.tbl_deep_extend("force", opts or {}, {
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
      opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, { "netcoredbg", "fantomas" })
      return opts
    end,
  },

  -- Roslyn LSP (replaces omnisharp + omnisharp-extended-lsp.nvim)
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {},
  },

  -- Treesitter parsers (from dotnet extra)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c_sharp", "fsharp" } },
  },

  -- Formatters (from dotnet extra)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        cs = { "lsp" },
        fsharp = { "fantomas" },
      },
    },
  },

  -- F# LSP (from dotnet extra)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        fsautocomplete = {},
      },
    },
  },

  -- Debug adapter (from dotnet extra)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      if not dap.adapters["netcoredbg"] then
        dap.adapters["netcoredbg"] = {
          type = "executable",
          command = vim.fn.exepath("netcoredbg"),
          args = { "--interpreter=vscode" },
          options = { detached = false },
        }
      end
      for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
        if not dap.configurations[lang] then
          dap.configurations[lang] = {
            {
              type = "netcoredbg",
              name = "Launch file",
              request = "launch",
              program = function()
                return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
              end,
              cwd = "${workspaceFolder}",
            },
          }
        end
      end
    end,
  },

  -- Test runner (from dotnet extra)
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "Nsidorenco/neotest-vstest" },
    opts = {
      adapters = {
        ["neotest-vstest"] = {},
      },
    },
  },
}
