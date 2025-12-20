local kind_icons = {
	Text = "󰉿",
	Method = "󰆧",
	Function = "󰊕",
	Constructor = "󰒓",
	Field = "󰇽",
	Variable = "󰫧",
	Property = "󰜢",
	Class = "󰠱",
	Interface = "",
	Struct = "󰙅",
	Module = "󰅩",
	Namespace = "󰅩",
	Package = "󰏗",
	Enum = "󰦑",
	EnumMember = "󰦑",
	Keyword = "󰌋",
	Snippet = "󱄽",
	Color = "󰏘",
	File = "󰈙",
	Reference = "󰈇",
	Folder = "󰉋",
	Event = "󰃭",
	Operator = "󰆕",
	TypeParameter = "󰊄",
}

return {
	"saghen/blink.cmp",
	version = "v0.*",
	event = "InsertEnter",
	opts = {
		keymap = {
			preset = "none",
			["<C-j>"] = { 'select_next', 'fallback' },
			["<C-k>"] = { "select_prev", "fallback" },
			["<CR>"] = { "accept", "fallback" },
		},
		snippets = {
			preset = "default",
		},
		appearance = { use_nvim_cmp_as_default = false },
		signature = {
			enabled = true,
			window = {
				border = "rounded",
				max_width = 200,
				scrollbar = false,
			},
		},
		cmdline = {
			sources = {},
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
				cs = { "lsp", "snippets", "buffer" },
			},
			providers = {
				--lsp = {
				--  -- don’t show LSP completions until we’ve typed at least 2 chars
				--  min_keyword_length = 2,
				--},
				--buffer = {
				--  min_keyword_length = 5,
				--},
				--path = {
				--  min_keyword_length = 1,
				--},
				--snippets = {
				--  min_keyword_length = 1,
				--},
			},
		},
		completion = {
			trigger = {
				show_on_blocked_trigger_characters = { '(' },
			},
			list = {
				selection = {
					preselect = true,
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 150,
				window = {
					border = "rounded",
					max_width = 80,
					max_height = 40,
				},
			},
			menu = {
				draw = {
					treesitter = { "lsp" },
					-- show source column with per-source colors
					columns = {
						{ "kind_icon" },
						{ "label", "label_description", gap = 1 },
						{ "source_name" },
					},
					components = {
						kind_icon = {
							text = function(ctx)
								local icon = kind_icons[ctx.kind] or ctx.kind_icon or ""
								return icon .. (ctx.icon_gap or " ")
							end,
							highlight = function(ctx)
								local kind = ctx.kind or ""
								local group = "BlinkCmpKind" .. kind
								return vim.fn.hlexists(group) == 1 and group or "BlinkCmpKind"
							end,
						},
						source_name = {
							text = function(ctx)
								return ctx.source_name
							end,
							highlight = function(ctx)
								local name = (ctx.source_name or ctx.source_id or ""):gsub("%W", "")
								if name == "" then
									return "BlinkCmpSource"
								end
								name = name:lower():gsub("^%l", string.upper)
								local group = "BlinkCmpSource" .. name
								return vim.fn.hlexists(group) == 1 and group or "BlinkCmpSource"
							end,
						},
					},
				},
			},
			ghost_text = {
				enabled = true,
			},
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
		},
	},
	config = function(_, opts)
		require("blink.cmp").setup(opts)
		-- Darken the completion menu + docs so they match a dark colorscheme
		--local function set_blink_highlights()
		--  local colors = {
		--    menu_bg = "#1a1b26",
		--    menu_fg = "#c0caf5",
		--    menu_border = "#3b4261",
		--    selection_bg = "#2a2e3f",
		--    doc_bg = "#11131d",
		--    ghost_fg = "#565f89",
		--  }

		--  local set = vim.api.nvim_set_hl
		--  set(0, "BlinkCmpMenu", { fg = colors.menu_fg, bg = colors.menu_bg })
		--  set(0, "BlinkCmpMenuBorder", { fg = colors.menu_border, bg = colors.menu_bg })
		--  set(0, "BlinkCmpMenuSelection", { fg = colors.menu_fg, bg = colors.selection_bg, bold = true })

		--  set(0, "BlinkCmpDoc", { fg = colors.menu_fg, bg = colors.doc_bg })
		--  set(0, "BlinkCmpDocBorder", { fg = colors.menu_border, bg = colors.doc_bg })
		--  set(0, "BlinkCmpDocSeparator", { fg = colors.menu_border, bg = colors.doc_bg })
		--  set(0, "BlinkCmpDocCursorLine", { bg = colors.selection_bg })

		--  set(0, "BlinkCmpSignatureHelp", { fg = colors.menu_fg, bg = colors.doc_bg })
		--  set(0, "BlinkCmpSignatureHelpBorder", { fg = colors.menu_border, bg = colors.doc_bg })
		--  set(0, "BlinkCmpGhostText", { fg = colors.ghost_fg, bg = colors.menu_bg, italic = true })
		--end

		--local group = vim.api.nvim_create_augroup("BlinkCmpCustomHighlights", { clear = true })
		--vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_blink_highlights })
		--set_blink_highlights()
	end,
}
