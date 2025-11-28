local dap, dapui = require("dap"), require("dapui")

dapui.setup({
  layouts = {
    {
      elements = {
        "scopes",
        "breakpoints",
        "stacks",
        "watches",
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 12,
      position = "bottom",
    },
  },
  floating = {
    border = "rounded",
  },
})

-- Auto open UI panels + console
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  local widgets = require("dap.ui.widgets")
  -- close sidebars but reopen console after closing
  dapui.close() -- close the left layout (scopes etc.)
--  require("dapui").open({ layout = 2 }) -- reopen bottom console layout
end

dap.listeners.before.event_exited["dapui_config"] = function()
  local widgets = require("dap.ui.widgets")
  dapui.close()
 -- require("dapui").open({ layout = 2 })
end
