-- lua/config/highlights.lua

local M         = {}

-- VS Dark+ synced TS + LSP colors
local OFFWHITE  = "#d4d4d4"
local OFFWHITE1 = "#FFE4BC"
local BLUE      = "#89b4fa" -- Catppuccin blue
local LBLUE     = "#89dceb"
local YELLOW    = "#dcdcaa"
local TEAL      = "#4ec9b0"
local ORANGE    = "#fab387"
local PGREEN    = "#a6e3a1"
local PURPLE    = "#cba6f7"
local IFACE     = "#b4befe"
local PINK      = "#f5c2e7"

local RB_PINK   = "#FF00FF"
local RB_YELLOW = "#ffd866"
local RB_BLUE   = "#6cb6ff"
local RB_ORANGE = "#ff8c42"
local RB_GREEN  = "#7ee787"
local RB_VIOLET = "#d199ff"
local RB_CYAN   = "#5ce1e6"

local COMMENT   = "#6c7086"
local BASE      = "#1e1e2e"
local SURFACE0  = "#45475a"
local SURFACE1  = "#585b70"

local function apply()
	local hl = vim.api.nvim_set_hl

	---------------------------------------------------------------------------
	-- Treesitter base
	---------------------------------------------------------------------------
	local base_ts = {
		["@string"]             = { fg = ORANGE },
		["@number"]             = { fg = PGREEN },
		["@boolean"]            = { fg = PGREEN },

		-- functions / methods
		["@function"]           = { fg = YELLOW },
		["@function.method"]    = { fg = YELLOW },
		["@method.call"]        = { fg = YELLOW },
		["@constructor"]        = { fg = YELLOW },

		-- types / namespaces
		["@type"]               = { fg = TEAL },
		["@type.interface"]     = { fg = IFACE },
		["@namespace"]          = { fg = OFFWHITE },

		-- identifiers
		["@variable"]           = { fg = LBLUE },
		["@field"]              = { fg = OFFWHITE },
		["@property"]           = { fg = OFFWHITE },
		["@variable.parameter"] = { fg = LBLUE },

		-- keywords
		["@keyword"]            = { fg = PURPLE },
		["@keyword.modifier"]   = { fg = BLUE },
		["@keyword.control"]    = { fg = PINK },
		["@variable.member"]    = { fg = OFFWHITE },
	}

	local lua_ts = {
		["@keyword.lua"]         = { fg = PURPLE },
		["@function.lua"]        = { fg = YELLOW },
		["@function.call.lua"]   = { fg = YELLOW },
		["@variable.lua"]        = { fg = LBLUE },
		["@variable.member.lua"] = { fg = BLUE },
		["@string.lua"]          = { fg = ORANGE },
		["@number.lua"]          = { fg = PGREEN },
		["@boolean.lua"]         = { fg = PGREEN },
		["@comment.lua"]         = { fg = COMMENT },
	}

	local ts_ts = {
		["@keyword.javascript"]             = { fg = PURPLE },
		["@keyword.typescript"]             = { fg = PURPLE },
		["@type.typescript"]                = { fg = TEAL },
		["@type.interface.typescript"]      = { fg = IFACE },
		["@function.call.typescript"]       = { fg = YELLOW },
		["@property.typescript"]            = { fg = OFFWHITE },
		["@variable.typescript"]            = { fg = LBLUE },
		["@variable.member.typescript"]     = { fg = OFFWHITE },
		["@punctuation.bracket.typescript"] = { fg = OFFWHITE },
	}

	local py_ts = {
		["@variable.member.python"]      = { fg = OFFWHITE },
		["@function.method.call.python"] = { fg = YELLOW },
	}

	---------------------------------------------------------------------------
	-- Extra groups (what used to be base46.hl_add)
	---------------------------------------------------------------------------
	local extra = {
		-- Rainbow delimiters
		RainbowDelimiterRed                    = { fg = RB_PINK },
		RainbowDelimiterYellow                 = { fg = RB_YELLOW },
		RainbowDelimiterBlue                   = { fg = RB_BLUE },
		RainbowDelimiterOrange                 = { fg = RB_ORANGE },
		RainbowDelimiterGreen                  = { fg = RB_GREEN },
		RainbowDelimiterViolet                 = { fg = RB_VIOLET },
		RainbowDelimiterCyan                   = { fg = RB_CYAN },

		-- C# semantic tokens
		["@lsp.type.parameter.cs"]             = { fg = LBLUE },
		["@lsp.type.namespace.cs"]             = { fg = OFFWHITE },
		["@lsp.type.keyword.cs"]               = { fg = BLUE },
		["@lsp.type.extensionMethod.cs"]       = { fg = YELLOW },
		["@lsp.type.interface.cs"]             = { fg = IFACE },
		["@lsp.type.property.cs"]              = { fg = OFFWHITE },
		["@lsp.type.controlKeyword.cs"]        = { fg = PINK },
		["@lsp.type.field.cs"]                 = { fg = OFFWHITE },
		["@lsp.type.variable.cs"]              = { fg = LBLUE },
		["@lsp.type.class.cs"]                 = { fg = TEAL },
		["@lsp.typemod.constant.static.cs"]    = { fg = OFFWHITE },

		["@variable.member.c_sharp"]           = { fg = OFFWHITE },
		["@variable.c_sharp"]                  = { fg = LBLUE },
		["@type.c_sharp"]                      = { fg = TEAL },
		["@function.method.call.c_sharp"]      = { fg = YELLOW },
		["@attribute.c_sharp"]                 = { fg = OFFWHITE },
		["@module.c_sharp"]                    = { fg = OFFWHITE },
		["@type.builtin.c_sharp"]              = { fg = BLUE },
		["@keyword.exception.c_sharp"]         = { fg = PURPLE },
		["@keyword.modifier.c_sharp"]          = { fg = BLUE },
		["@keyword.type.c_sharp"]              = { fg = BLUE },

		-- Lua LSP semantics
		["@lsp.type.variable.lua"]             = { fg = LBLUE },
		["@lsp.type.parameter.lua"]            = { fg = LBLUE },
		["@lsp.type.property.lua"]             = { fg = OFFWHITE },
		["@lsp.type.function.lua"]             = { fg = YELLOW },
		["@function.call.lua"]                 = { fg = YELLOW },
		["@variable.member.lua"]               = { fg = BLUE },

		-- TS LSP semantics
		["@lsp.type.parameter.typescript"]     = { fg = LBLUE },
		["@lsp.type.property.typescript"]      = { fg = OFFWHITE },
		["@lsp.type.variable.typescript"]      = { fg = LBLUE },
		["@lsp.type.interface.typescript"]     = { fg = IFACE },
		["@lsp.type.typeParameter.typescript"] = { fg = TEAL },
		["@lsp.type.enumMember.typescript"]    = { fg = OFFWHITE },

		-- Python semantics
		["@function.builtin.python"]           = { fg = BLUE },
		["@function.call.python"]              = { fg = YELLOW },
		["@module.python"]                     = { fg = OFFWHITE },
		["@keyword.repeat.python"]             = { fg = PURPLE },

		-- Neo-tree / devicons
		Directory                              = { fg = RB_YELLOW },
		MiniIconsDirectory                     = { fg = RB_YELLOW },
		NeoTreeDirectoryIcon                   = { fg = RB_YELLOW },
		DevIconCs                              = { fg = PGREEN },
		DevIconCSharpProject                   = { fg = OFFWHITE },
		NeoTreeCsharpProjectIcon               = { fg = PGREEN },
		NeoTreeSolutionIcon                    = { fg = PURPLE },

		-- LazyGit (Snacks)
		LazyGitActiveBorder                    = { fg = TEAL },

		-- Popup menu
		Pmenu                                  = { fg = OFFWHITE, bg = BASE },
		PmenuSel                               = { fg = BASE, bg = BLUE, bold = true },
		PmenuSbar                              = { bg = SURFACE0 },
		PmenuThumb                             = { bg = SURFACE1 },

		-- Flash.nvim
		FlashLabel                             = { fg = BASE, bg = PINK, bold = true },
		FlashMatch                             = { fg = BASE, bg = PGREEN, bold = true },
		FlashCurrent                           = { fg = BASE, bg = PGREEN, bold = true },
		FlashBackdrop                          = { fg = SURFACE0 },

		WinSeparator                           = { fg = SURFACE0 },
	}

	local snacks_picker = {
		SnacksPicker = { link = "Normal" },
		SnacksPickerList = { link = "Normal" },
		SnacksPickerPreview = { link = "Normal" },
		SnacksPickerInput = { link = "Normal" },
		SnacksPickerBox = { link = "Normal" },
		SnacksPickerBorder = { fg = SURFACE0 },
		SnacksPickerTitle = { fg = OFFWHITE, bg = BASE },
		SnacksPickerDirectory = { fg = OFFWHITE1 },
	}

	local blink = {
		BlinkCmpDoc = { fg = OFFWHITE, bg = BASE },
		BlinkCmpDocBorder = { fg = SURFACE0, bg = BASE },
		BlinkCmpDocSeparator = { fg = SURFACE0, bg = BASE },
		BlinkCmpDocCursorLine = { bg = SURFACE0 },
		BlinkCmpSignatureHelp = { fg = OFFWHITE, bg = BASE },
		BlinkCmpSignatureHelpBorder = { fg = SURFACE0, bg = BASE },
		BlinkCmpGhostText = { fg = COMMENT, bg = BASE, italic = true },
	}

	local noice = {
		NoiceCmdlinePopupBorder = { fg = OFFWHITE },
		NoiceCmdlinePopupTitle = { fg = OFFWHITE, bg = BASE, bold = true },
		NoicePopupmenuBorder = { fg = SURFACE0 },
		NoicePopupmenuSelected = { bg = SURFACE0 },
		NoicePopupBorder = { fg = SURFACE0 },
		NoiceConfirmBorder = { fg = SURFACE0 },
		NoiceMiniBorder = { fg = SURFACE0 },
	}

	-- Apply all at once
	for group, spec in pairs(base_ts) do
		hl(0, group, spec)
	end
	for group, spec in pairs(lua_ts) do
		hl(0, group, spec)
	end
	for group, spec in pairs(ts_ts) do
		hl(0, group, spec)
	end
	for group, spec in pairs(py_ts) do
		hl(0, group, spec)
	end
	for group, spec in pairs(extra) do
		hl(0, group, spec)
	end
	for group, spec in pairs(snacks_picker) do
		hl(0, group, spec)
	end
	for group, spec in pairs(blink) do
		hl(0, group, spec)
	end
	for group, spec in pairs(noice) do
		hl(0, group, spec)
	end
end

function M.setup()
	-- apply once
	apply()

	-- re-apply after changing colourscheme
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = apply,
	})
end

return M
