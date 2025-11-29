-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
-- VS Dark+ synced TS + LSP colors
local VS_OFFWHITE = "#d4d4d4"
local VS_BLUE = "#569cd6" -- your darker blue choice
local VS_LBLUE = "#9cdcfe" -- light blue
local VS_YELLOW = "#dcdcaa"
local VS_TEAL = "#4ec9b0"
local VS_ORANGE = "#ce9178"
local VS_PGREEN = "#b5cea8"
local VS_PURPLE = "#c586c0"
local VS_IFACE = "#9ed6a2"

M.base46 = {
  theme = "default-dark",
  transparency = false,
  hl_override = (function()
    local base = {
      ["@string"] = { fg = VS_ORANGE },
      ["@number"] = { fg = VS_PGREEN },
      ["@boolean"] = { fg = VS_PGREEN },

      -- functions / methods
      ["@function"] = { fg = VS_YELLOW },
      ["@function.method"] = { fg = VS_YELLOW },
      ["@method.call"] = { fg = VS_YELLOW },
      ["@constructor"] = { fg = VS_YELLOW },

      -- types / namespaces
      ["@type"] = { fg = VS_TEAL }, -- classes/structs by default
      ["@type.interface"] = { fg = VS_IFACE }, -- interfaces (TS supports this in c_sharp)
      ["@namespace"] = { fg = VS_OFFWHITE }, -- match your LSP namespace color

      -- identifiers
      ["@variable"] = { fg = VS_LBLUE }, -- match LSP variable
      ["@field"] = { fg = VS_OFFWHITE }, -- match LSP field
      ["@property"] = { fg = VS_OFFWHITE }, -- match LSP property
      ["@variable.parameter"] = { fg = VS_LBLUE }, -- match LSP parameter

      -- keywords
      ["@keyword"] = { fg = VS_PURPLE }, -- if/return/for…
      ["@keyword.modifier"] = { fg = VS_BLUE }, -- var/async/await/static
      ["@keyword.control"] = { fg = "#d8a0df" }, -- to mirror your LSP controlKeyword
    }

    local lua_specific = {
      ["@keyword.lua"] = { fg = VS_PURPLE },
      ["@function.lua"] = { fg = VS_YELLOW },
      ["@function.call.lua"] = { fg = VS_YELLOW },
      ["@variable.lua"] = { fg = VS_LBLUE },
      ["@variable.member.lua"] = { fg = VS_BLUE },
      ["@string.lua"] = { fg = VS_ORANGE },
      ["@number.lua"] = { fg = VS_PGREEN },
      ["@boolean.lua"] = { fg = VS_PGREEN },
      ["@comment.lua"] = { fg = "#6a9955" },
    }

    local ts_specific = {
      ["@keyword.javascript"] = { fg = VS_PURPLE },
      ["@keyword.typescript"] = { fg = VS_PURPLE },
      ["@type.typescript"] = { fg = VS_TEAL },
      ["@type.interface.typescript"] = { fg = VS_IFACE },
      ["@function.call.typescript"] = { fg = VS_YELLOW },
      ["@property.typescript"] = { fg = VS_OFFWHITE },
      ["@variable.typescript"] = { fg = VS_LBLUE },
      ["@variable.member.typescript"] = { fg = VS_OFFWHITE },
      ["@punctuation.bracket.typescript"] = { fg = VS_OFFWHITE },
    }

    return vim.tbl_extend("force", base, lua_specific, ts_specific)
  end)(),
  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
  hl_add = {
    RainbowDelimiterRed = { fg = "#ffd700" },
    RainbowDelimiterYellow = { fg = "#dcdcaa" },
    RainbowDelimiterBlue = { fg = "#9cdcfe" },
    RainbowDelimiterOrange = { fg = "#FFAC1C" },
    RainbowDelimiterGreen = { fg = "#6a9955" },
    RainbowDelimiterViolet = { fg = "#c586c0" },
    RainbowDelimiterCyan = { fg = "#4ec9b0" },
    -- C# semantics
    ["@lsp.type.parameter.cs"] = { fg = VS_LBLUE },
    ["@lsp.type.namespace.cs"] = { fg = VS_OFFWHITE },
    ["@lsp.type.keyword.cs"] = { fg = VS_BLUE },
    ["@lsp.type.extensionMethod.cs"] = { fg = VS_YELLOW },
    ["@lsp.type.interface.cs"] = { fg = VS_IFACE },
    ["@lsp.type.property.cs"] = { fg = VS_OFFWHITE },
    ["@lsp.type.controlKeyword.cs"] = { fg = "#d8a0df" },
    ["@lsp.type.field.cs"] = { fg = VS_OFFWHITE },
    ["@lsp.type.variable.cs"] = { fg = VS_LBLUE },
    ["@lsp.type.class.cs"] = { fg = VS_TEAL },
    ["@lsp.typemod.constant.static.cs"] = { fg = VS_OFFWHITE },
    ["@variable.member.c_sharp"] = { fg = VS_OFFWHITE },
    ["@variable.c_sharp"] = { fg = VS_LBLUE },
    ["@type.c_sharp"] = { fg = VS_TEAL },
    ["@function.method.call.c_sharp"] = { fg = VS_YELLOW },
    ["@attribute.c_sharp"] = { fg = VS_OFFWHITE },
    ["@module.c_sharp"] = { fg = VS_OFFWHITE },
    ["@type.builtin.c_sharp"] = { fg = VS_BLUE },
    ["@keyword.exception.c_sharp"] = { fg = VS_PURPLE },
    ["@keyword.modifier.c_sharp"] = { fg = VS_BLUE },
    ["@keyword.type.c_sharp"] = { fg = VS_BLUE },

    -- Lua semantics
    ["@lsp.type.variable.lua"] = { fg = VS_LBLUE },
    ["@lsp.type.parameter.lua"] = { fg = VS_LBLUE },
    ["@lsp.type.property.lua"] = { fg = VS_OFFWHITE },
    ["@lsp.type.function.lua"] = { fg = VS_YELLOW },
    ["@function.call.lua"] = { fg = VS_YELLOW },
    ["@variable.member.lua"] = { fg = VS_BLUE },

    -- TypeScript semantics
    ["@lsp.type.parameter.typescript"] = { fg = VS_LBLUE },
    ["@lsp.type.property.typescript"] = { fg = VS_OFFWHITE },
    ["@lsp.type.variable.typescript"] = { fg = VS_LBLUE },
    ["@lsp.type.interface.typescript"] = { fg = VS_IFACE },
    ["@lsp.type.typeParameter.typescript"] = { fg = VS_TEAL },
    ["@lsp.type.enumMember.typescript"] = { fg = VS_OFFWHITE },

    NeoTreeDirectoryIcon = { fg = "#ffcf4a" },
    DevIconCs = { fg = "#00b600" },
    DevIconCSharpProject = { fg = "#ffffff" },

    Pmenu = { fg = "#D4D4D4", bg = "#2D2D30" },
    PmenuSel = { fg = "#ffffff", bg = "#07AACC", bold = true },
    PmenuSbar = { bg = "#333333" },
    PmenuThumb = { bg = "#569Cd6" },
    NeoTreeCsharpProjectIcon = { fg = "#00b600" },
    NeoTreeSolutionIcon = { fg = VS_PURPLE },

-- Flash.nvim highlights: bright labels + dimmed backdrop
    FlashLabel = { fg = "#d4d4d4", bg = "#3a3a3a", bold = true },
    FlashMatch = { fg = "#ff9e64", bg = "#3a3a3a", bold = true },
    FlashCurrent = { fg = "#1e1e1e", bg = "#3a3a3a", bold = true },
    FlashBackdrop = { fg = "#4a4a4a" },

  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "███╗   ██╗███████╗██████╗ ██████╗ ",
    "████╗  ██║██╔════╝██╔══██╗██╔══██╗",
    "██╔██╗ ██║█████╗  ██████╔╝██║  ██║",
    "██║╚██╗██║██╔══╝  ██╔══██╗██║  ██║",
    "██║ ╚████║███████╗██║  ██║██████╔╝",
    "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝ ",
    "                                  ",
  },
}

M.ui = {
  telescope = {
    style = "bordered",
  },
  tabufline = {
    lazyload = false,
  }
}

return M
