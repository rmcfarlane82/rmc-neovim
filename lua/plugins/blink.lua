local kind_icons = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "󰒓",
  Field = "󰇽",
  Variable = "󰫧",
  Property = "󰜢",
  Class = "󰠱",
  Interface = "",
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
  opts = {
    appearance = { use_nvim_cmp_as_default = false },
    completion = {
      documentation = {
        window = {
          border = "rounded",
        },
      },
      menu = {
        border = "rounded",
        draw = {
          columns = {
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "source_name" },
          },
          components = {
            kind_icon = {
              text = function(ctx)
                local icon = kind_icons[ctx.kind] or ctx.kind_icon or ""
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
    },
  },
}
