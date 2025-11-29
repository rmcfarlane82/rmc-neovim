return {
  {
    "rafamadriz/friendly-snippets",
    event = "InsertEnter",
    config = function()
      local ok, luasnip = pcall(require, "luasnip")
      if not ok then
        return
      end

      require("luasnip.loaders.from_vscode").lazy_load()

      luasnip.config.set_config {
        region_check_events = "CursorHold,InsertLeave",
        delete_check_events = "TextChanged",
      }
    end,
  },
}
