local M = {}
local PATH_SEP = package.config:sub(1, 1)
local LAUNCH_SETTINGS_SEGMENTS = { "Properties", "launchSettings.json" }

local function ensure_telescope()
  if not package.loaded["telescope"] then
    local ok, lazy = pcall(require, "lazy")
    if ok then
      lazy.load { plugins = { "telescope.nvim" } }
    end
  end

  if package.loaded["telescope"] then
    return true
  end

  local ok = pcall(require, "telescope")
  return ok
end

local function ensure_dotnet()
  if vim.fn.executable "dotnet" == 1 then
    return true
  end

  vim.notify("dotnet CLI not found in PATH", vim.log.levels.ERROR)
  return false
end

local function ensure_dap()
  if package.loaded["dap"] then
    return true
  end

  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    lazy.load { plugins = { "nvim-dap" } }
  end

  if package.loaded["dap"] then
    return true
  end

  local ok = pcall(require, "dap")
  if not ok then
    vim.notify("nvim-dap is not available", vim.log.levels.ERROR)
    return false
  end
  return true
end

local function open_terminal(cmd, cwd)
  local parts = {}
  for _, arg in ipairs(cmd) do
    table.insert(parts, vim.fn.shellescape(arg))
  end
  local run_cmd = table.concat(parts, " ")
  vim.cmd "botright 15split"
  vim.cmd(string.format("lcd %s", vim.fn.fnameescape(cwd)))
  vim.cmd("terminal " .. run_cmd)
  vim.cmd "lcd -"
  vim.cmd "startinsert"
end

local function find_projects(opts)
  local scan = require "plenary.scandir"
  local cwd = opts.cwd or vim.loop.cwd()
  local depth = opts.depth or 8

  return scan.scan_dir(cwd, {
    add_dirs = false,
    depth = depth,
    search_pattern = "%.csproj$",
  })
end

local function project_dir(project_path)
  return vim.fn.fnamemodify(project_path, ":h")
end

local function launch_settings_path(project_path)
  local segments = { project_dir(project_path) }
  vim.list_extend(segments, LAUNCH_SETTINGS_SEGMENTS)
  return table.concat(segments, PATH_SEP)
end

local function read_launch_profiles(project_path)
  local launch_file = launch_settings_path(project_path)
  if vim.fn.filereadable(launch_file) == 0 then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(launch_file), "\n"))
  if not ok or type(decoded) ~= "table" then
    vim.notify("Failed to parse launchSettings.json for " .. project_path, vim.log.levels.WARN)
    return nil
  end

  local profiles = decoded.profiles
  if type(profiles) ~= "table" then
    return nil
  end

  local list = {}
  for name, profile in pairs(profiles) do
    local env = {}
    if type(profile.environmentVariables) == "table" then
      for key, value in pairs(profile.environmentVariables) do
        env[key] = tostring(value)
      end
    end
    if type(profile.applicationUrl) == "string" and profile.applicationUrl ~= "" then
      env.ASPNETCORE_URLS = env.ASPNETCORE_URLS or profile.applicationUrl
    end
    table.insert(list, { name = name, env = env })
  end

  if vim.tbl_isempty(list) then
    return nil
  end

  table.sort(list, function(a, b)
    return a.name < b.name
  end)

  return list
end

local function pick_launch_profile(project_path, cb)
  local profiles = read_launch_profiles(project_path)
  if not profiles then
    cb(nil)
    return
  end

  if #profiles == 1 then
    cb(profiles[1])
    return
  end

  ensure_telescope()
  vim.ui.select(profiles, {
    prompt = "Select launch profile",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    cb(choice)
  end)
end

local function build_project(project_path)
  vim.notify("dotnet build " .. vim.fn.fnamemodify(project_path, ":t"), vim.log.levels.INFO)
  local cmd = { "dotnet", "build", project_path, "-c", "Debug" }
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify(output, vim.log.levels.ERROR, { title = "dotnet build failed" })
    return false
  end
  return true
end

local function find_output_dll(project_path)
  local dir = project_dir(project_path)
  local target = vim.fn.fnamemodify(project_path, ":t:r") .. ".dll"
  local results = vim.fs.find(function(name, path)
    if name ~= target then
      return false
    end
    local full = path .. PATH_SEP .. name
    if full:find("bin/Debug", 1, true) or full:find("bin\\Debug", 1, true) then
      return true
    end
    return false
  end, { type = "file", limit = 1, path = dir })
  return results and results[1] or nil
end

local function pick_project(opts, title, cb)
  if not ensure_dotnet() or not ensure_telescope() then
    return
  end

  local projects = find_projects(opts or {})
  if vim.tbl_isempty(projects) then
    vim.notify("No .csproj files found", vim.log.levels.WARN)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  pickers
    .new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = projects,
        entry_maker = function(path)
          return {
            value = path,
            display = vim.fn.fnamemodify(path, ":~:."),
            ordinal = path,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection or not selection.value then
            return
          end
          cb(selection.value)
        end)
        return true
      end,
    })
    :find()
end

function M.run_project(project_path)
  if not ensure_dotnet() then
    return
  end

  if not project_path or project_path == "" then
    vim.notify("Invalid project path", vim.log.levels.WARN)
    return
  end

  local cwd = project_dir(project_path)
  open_terminal({ "dotnet", "run", "--project", project_path }, cwd)
end

function M.run_tests(project_path, opts)
  if not ensure_dotnet() then
    return
  end

  local cwd = project_dir(project_path)
  local cmd = { "dotnet", "test", "--project", project_path }
  if opts and opts.test_args then
    vim.list_extend(cmd, opts.test_args)
  end
  open_terminal(cmd, cwd)
end

function M.debug_project(project_path, opts)
  if not ensure_dotnet() or not ensure_dap() then
    return
  end

  if not build_project(project_path) then
    return
  end

  local dll = find_output_dll(project_path)
  if not dll then
    vim.notify("Unable to find build output for " .. project_path, vim.log.levels.ERROR)
    return
  end

  local dap = require "dap"
  local function launch_with_profile(profile)
    local base_config = {
      type = "coreclr",
      name = "Launch " .. vim.fn.fnamemodify(project_path, ":t"),
      request = "launch",
      program = dll,
      cwd = project_dir(project_path),
      stopAtEntry = false,
      justMyCode = true,
    }

    if profile and profile.env and not vim.tbl_isempty(profile.env) then
      base_config.env = profile.env
      base_config.name = base_config.name .. " (" .. profile.name .. ")"
    end

    local config = vim.tbl_deep_extend("force", base_config, opts and opts.dap_config or {})
    dap.run(config)
  end

  pick_launch_profile(project_path, function(profile)
    launch_with_profile(profile)
  end)
end

function M.pick_and_run(opts)
  pick_project(opts, "dotnet run project", function(path)
    M.run_project(path)
  end)
end

function M.pick_and_test(opts)
  pick_project(opts, "dotnet test project", function(path)
    M.run_tests(path, opts)
  end)
end

function M.pick_and_debug(opts)
  pick_project(opts, "dotnet debug project", function(path)
    M.debug_project(path, opts)
  end)
end

return M
