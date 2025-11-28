
local dap = require("dap")

-- ---- adapter (fix the path if needed) ----
local function get_dotnet_path()
    if vim.loop.os_uname().version:match("Windows") then
        return [[\mason\packages\netcoredbg\netcoredbg\netcoredbg.exe]]
    end
   return [[/mason/packages/netcoredbg/netcoredbg]]
end

local mason_path = vim.fn.stdpath("data") .. get_dotnet_path()

dap.adapters.netcoredbg = {
  type = "executable",
  command = mason_path,
  args = { "--interpreter=vscode" },
}
dap.adapters.coreclr = dap.adapters.netcoredbg

-- ---- DAP configurations for C# ----
dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch (prompt for dll)",
    request = "launch",
    program = function()
      local default_path = vim.fn.getcwd() .. "/bin/Debug/"
      local dll = vim.fn.input("Path to dll: ", default_path, "file")
      assert(dll and #dll > 0, "No DLL selected")
      return dll
    end,
    cwd = "${workspaceFolder}",
    stopAtEntry = false,
    justMyCode = true,
  },
  {
    type = "coreclr",
    name = "Attach (pick process)",
    request = "attach",
    processId = require("dap.utils").pick_process,
  },
}


require("dap.ext.vscode").load_launchjs(nil, { coreclr = { "cs" } })

