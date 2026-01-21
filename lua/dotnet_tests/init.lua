local M = {}

local SymbolKind = vim.lsp.protocol.SymbolKind

local state = {
  test_projects_by_root = {},
}

local ensure_results_buf
local open_results_split
local set_results_content
local append_results_content
local set_quickfix_items
local combined_output
local execute_dotnet_test
local parse_trx_failed_tests
local relpath_from_root

local run_dotnet_test

local test_attributes = {
  "Fact",
  "Theory",
  "Test",
  "TestCase",
  "TestMethod",
}

-- Small helper so async callbacks always notify on the main loop.
local function notify(level, msg)
  vim.schedule(function()
    vim.notify(msg, level)
  end)
end

-- Check whether a cursor position is within an LSP range.
local function range_contains_pos(range, pos)
  local start = range.start
  local finish = range["end"]
  if pos.line < start.line or (pos.line == start.line and pos.character < start.character) then
    return false
  end
  if pos.line > finish.line or (pos.line == finish.line and pos.character > finish.character) then
    return false
  end
  return true
end

-- Prefer the smallest range so we get the innermost method.
local function range_size(range)
  return (range["end"].line - range.start.line) * 100000 + (range["end"].character - range.start.character)
end

-- Symbol kinds that contribute to FullyQualifiedName.
local function is_scope_symbol(kind)
  return kind == SymbolKind.Namespace
    or kind == SymbolKind.Class
    or kind == SymbolKind.Struct
    or kind == SymbolKind.Interface
    or kind == SymbolKind.Enum
    or kind == SymbolKind.Module
end

-- Method symbols are the leaf we want.
local function is_method_symbol(kind)
  return kind == SymbolKind.Method
end

-- Walk hierarchical DocumentSymbol output to find the nearest method and its scope.
local function find_method_in_document_symbols(symbols, cursor)
  local best

  local function walk(nodes, scope)
    for _, sym in ipairs(nodes) do
      if sym.range and range_contains_pos(sym.range, cursor) then
        local next_scope = scope
        if is_scope_symbol(sym.kind) then
          next_scope = vim.list_extend(vim.deepcopy(scope), { sym.name })
        end

        if is_method_symbol(sym.kind) then
          local size = range_size(sym.range)
          if not best or size < best.size then
            best = {
              symbol = sym,
              scope = scope,
              size = size,
            }
          end
        end

        if sym.children then
          walk(sym.children, next_scope)
        end
      end
    end
  end

  walk(symbols, {})
  return best
end

-- Fallback for SymbolInformation output (flat list) using containerName.
local function find_method_in_symbol_info(symbols, cursor)
  local best
  for _, sym in ipairs(symbols) do
    local range = sym.location and sym.location.range
    if range and is_method_symbol(sym.kind) and range_contains_pos(range, cursor) then
      local size = range_size(range)
      if not best or size < best.size then
        local scope = {}
        if sym.containerName and sym.containerName ~= "" then
          scope = vim.split(sym.containerName, ".", { plain = true })
        end
        best = {
          symbol = sym,
          scope = scope,
          size = size,
        }
      end
    end
  end
  return best
end

-- Scan a few lines above the method for common test attributes.
local function has_test_attribute(bufnr, start_line)
  local from_line = math.max(0, start_line - 6)
  -- Include start_line since some LSP servers start the range on the attribute line.
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_line, start_line + 1, false)
  for _, line in ipairs(lines) do
    for _, attr in ipairs(test_attributes) do
      local prefix = "%[%s*" .. attr
      if line:match(prefix .. "%s*%]") or line:match(prefix .. "%s*,") or line:match(prefix .. "%s*%(") then
        return true
      end
    end
  end
  return false
end

local function collect_tests_from_document_symbols(symbols, bufnr)
  local tests = {}

  local function walk(nodes, scope)
    for _, sym in ipairs(nodes) do
      local next_scope = scope
      if is_scope_symbol(sym.kind) then
        next_scope = vim.list_extend(vim.deepcopy(scope), { sym.name })
      end

      if is_method_symbol(sym.kind) and sym.range then
        if has_test_attribute(bufnr, sym.range.start.line) then
          table.insert(tests, { symbol = sym, scope = scope })
        end
      end

      if sym.children then
        walk(sym.children, next_scope)
      end
    end
  end

  walk(symbols, {})
  return tests
end

local function collect_tests_from_symbol_info(symbols, bufnr)
  local tests = {}
  for _, sym in ipairs(symbols) do
    local range = sym.location and sym.location.range
    if range and is_method_symbol(sym.kind) then
      if has_test_attribute(bufnr, range.start.line) then
        local scope = {}
        if sym.containerName and sym.containerName ~= "" then
          scope = vim.split(sym.containerName, ".", { plain = true })
        end
        table.insert(tests, { symbol = sym, scope = scope })
      end
    end
  end
  return tests
end

-- Try to read the namespace declaration from the top of the file.
local function get_namespace_from_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 80, false)
  for _, line in ipairs(lines) do
    local ns = line:match("^%s*namespace%s+([%w%._]+)%s*[;{]")
    if ns then
      return ns
    end
  end
  return nil
end

local function build_fqn(bufnr, scope, method_name)
  local parts = vim.deepcopy(scope)
  local ns = get_namespace_from_buffer(bufnr)
  if ns and (parts[1] ~= ns) then
    table.insert(parts, 1, ns)
  end
  table.insert(parts, method_name)
  return table.concat(parts, ".")
end

local function build_scope_fqn(bufnr, scope)
  local parts = vim.deepcopy(scope)
  local ns = get_namespace_from_buffer(bufnr)
  if ns and (parts[1] ~= ns) then
    table.insert(parts, 1, ns)
  end
  return table.concat(parts, ".")
end

local function build_filter_for_tests(tests, bufnr)
  local max_len = 1500
  local filters = {}
  for _, item in ipairs(tests) do
    local fqn = build_fqn(bufnr, item.scope, item.symbol.name)
    table.insert(filters, "FullyQualifiedName=" .. fqn)
  end

  local exact = table.concat(filters, "|")
  if #exact <= max_len then
    return exact, "exact", nil
  end

  local class_filters = {}
  local seen = {}
  for _, item in ipairs(tests) do
    local class_fqn = build_scope_fqn(bufnr, item.scope)
    if class_fqn ~= "" and not seen[class_fqn] then
      seen[class_fqn] = true
      table.insert(class_filters, "FullyQualifiedName~" .. class_fqn)
    end
  end

  local class_expr = table.concat(class_filters, "|")
  if class_expr ~= "" and #class_expr <= max_len then
    return class_expr, "class", "Filter too long; using class-level filter"
  end

  return nil, "project", "Filter too long; running full project"
end

local function find_root(start_dir)
  local sln = vim.fs.find(function(name)
    return name:match("%.sln$")
  end, { path = start_dir, upward = true, type = "file", limit = 1 })
  if sln[1] then
    return vim.fs.dirname(sln[1])
  end

  local git = vim.fs.find(function(name)
    return name == ".git"
  end, { path = start_dir, upward = true, type = "directory", limit = 1 })
  if git[1] then
    return vim.fs.dirname(git[1])
  end

  return nil
end

local function is_test_project(csproj_path)
  local ok, lines = pcall(vim.fn.readfile, csproj_path)
  if not ok or not lines then
    return false
  end

  local content = string.lower(table.concat(lines, "\n"))
  if content:find("microsoft.net.test.sdk", 1, true) then
    return true
  end
  if content:find('packagereference include="xunit"', 1, true) then
    return true
  end
  if content:find('packagereference include="nunit"', 1, true) then
    return true
  end
  if content:find('packagereference include="mstest.testframework"', 1, true) then
    return true
  end

  return false
end

local function discover_test_projects(root)
  local matches = vim.fs.find(function(name, path)
    if not name:match("%.csproj$") then
      return false
    end
    if path:find("/bin/") or path:find("/obj/") or path:find("/.git/") then
      return false
    end
    return true
  end, { path = root, type = "file", limit = math.huge })

  local results = {}
  for _, csproj in ipairs(matches) do
    if is_test_project(csproj) then
      table.insert(results, csproj)
    end
  end

  table.sort(results)
  return results
end

local function get_cached_test_projects(root, refresh)
  if not refresh and state.test_projects_by_root[root] then
    return state.test_projects_by_root[root]
  end
  local projects = discover_test_projects(root)
  state.test_projects_by_root[root] = projects
  return projects
end

relpath_from_root = function(root, path)
  local rel = vim.fs.relpath(root, path)
  if rel then
    return rel
  end
  return vim.fn.fnamemodify(path, ":.")
end

local function run_project_tests(csproj_path, header_label)
  run_dotnet_test(csproj_path, nil, header_label, "project", nil)
end

local function run_multiple_projects(csproj_paths, root)
  notify(vim.log.levels.INFO, "Running .NET tests...")

  local buf = ensure_results_buf()
  local header = {
    "Dotnet test results",
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S"),
    "Target: All test projects",
    "Root: " .. root,
    "Projects: " .. tostring(#csproj_paths),
  }
  set_results_content(buf, header, "")
  open_results_split(buf)

  local combined_items = {}
  local any_failed = false
  local index = 1

  local function run_next()
    local csproj = csproj_paths[index]
    if not csproj then
      set_quickfix_items(combined_items)
      if any_failed then
        notify(vim.log.levels.WARN, "Some test projects failed")
      else
        notify(vim.log.levels.INFO, "All test projects passed")
      end
      return
    end

    local rel = relpath_from_root(root, csproj)
    local separator = {
      string.rep("=", 60),
      "Project: " .. rel,
      string.rep("-", 60),
    }
    append_results_content(buf, separator)

    execute_dotnet_test(csproj, nil, function(obj, trx_path)
      local combined = combined_output(obj)
      local lines = vim.split(combined, "\n", { plain = true })
      append_results_content(buf, lines)

      if obj.code ~= 0 then
        any_failed = true
      end

      local items = parse_trx_failed_tests(trx_path)
      if items and #items > 0 then
        vim.list_extend(combined_items, items)
      end

      index = index + 1
      run_next()
    end)
  end

  run_next()
end

-- Find the closest .csproj by walking upward from the current file directory.
local function find_csproj(start_dir)
  local matches = vim.fs.find(function(name)
    return name:match("%.csproj$")
  end, { path = start_dir, upward = true, type = "file", limit = 1 })
  return matches[1]
end

ensure_results_buf = function()
  local name = "Dotnet Test Results"
  local existing = vim.fn.bufnr(name)
  if existing > 0 then
    return existing
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dotnettest"
  return buf
end

open_results_split = function(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_height(win, 15)
      return
    end
  end

  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, bufnr)
end

set_results_content = function(bufnr, header_lines, output)
  local lines = {}
  for _, line in ipairs(header_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  for _, line in ipairs(vim.split(output, "\n", { plain = true })) do
    table.insert(lines, line)
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

append_results_content = function(bufnr, lines)
  if not lines or #lines == 0 then
    return
  end
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

local function set_quickfix_from_output(output)
  local items = {}
  for _, line in ipairs(vim.split(output, "\n", { plain = true, trimempty = true })) do
    local file, lnum = line:match("%s+in%s+([^:]+):line%s+(%d+)")
    if file and lnum then
      table.insert(items, {
        filename = file,
        lnum = tonumber(lnum),
        text = vim.trim(line),
      })
    end
  end

  if #items > 0 then
    vim.fn.setqflist({}, "r", { title = "Dotnet Test Results", items = items })
  end
end

local function build_trx_path()
  return vim.fn.tempname() .. ".trx"
end

parse_trx_failed_tests = function(trx_path)
  local ok, lines = pcall(vim.fn.readfile, trx_path)
  if not ok or not lines then
    return {}
  end

  local items = {}
  local collecting = false
  local block_lines = {}

  local function handle_block(block)
    local outcome = block:match('outcome="([^"]+)"')
    if outcome ~= "Failed" then
      return
    end

    local test_name = block:match('testName="([^"]+)"') or "Unknown test"
    local message = block:match("<Message>(.-)</Message>") or ""
    local stack = block:match("<StackTrace>(.-)</StackTrace>") or ""
    message = message:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    stack = stack:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")

    local file, lnum = stack:match("%s+in%s+([^:]+):line%s+(%d+)")
    local msg_line = vim.split(vim.trim(message), "\n", { plain = true })[1] or ""
    local text = test_name
    if msg_line ~= "" then
      text = text .. ": " .. msg_line
    end

    local item = { text = text }
    if file and lnum then
      item.filename = file
      item.lnum = tonumber(lnum)
    end
    table.insert(items, item)
  end

  for _, line in ipairs(lines) do
    if not collecting and line:find("<UnitTestResult") then
      collecting = true
      block_lines = { line }
    elseif collecting then
      table.insert(block_lines, line)
    end

    if collecting and line:find("</UnitTestResult>") then
      collecting = false
      handle_block(table.concat(block_lines, "\n"))
      block_lines = {}
    end
  end

  return items
end

local function set_quickfix_from_trx(trx_path)
  local items = parse_trx_failed_tests(trx_path)
  if #items > 0 then
    vim.fn.setqflist({}, "r", { title = "Dotnet Test Results", items = items })
  end
end

set_quickfix_items = function(items)
  if items and #items > 0 then
    vim.fn.setqflist({}, "r", { title = "Dotnet Test Results", items = items })
  end
end

combined_output = function(obj)
  local stdout = obj.stdout or ""
  local stderr = obj.stderr or ""
  if stderr ~= "" then
    return stdout .. "\n" .. stderr
  end
  return stdout
end

execute_dotnet_test = function(csproj, filter_expr, callback)
  local trx_path = build_trx_path()
  local cmd = {
    "dotnet",
    "test",
    csproj,
    "--no-build",
    "--logger",
    "trx;LogFileName=" .. trx_path,
  }

  if filter_expr and filter_expr ~= "" then
    table.insert(cmd, "--filter")
    table.insert(cmd, filter_expr)
  end

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      callback(obj, trx_path)
    end)
  end)
end

-- Run dotnet test with a FullyQualifiedName filter.
run_dotnet_test = function(csproj, filter_expr, target_label, filter_mode, filter_note)
  notify(vim.log.levels.INFO, "Running .NET tests...")

  execute_dotnet_test(csproj, filter_expr, function(obj, trx_path)
    local combined = combined_output(obj)

    local header = {
      "Dotnet test results",
      "Time: " .. os.date("%Y-%m-%d %H:%M:%S"),
      "Project: " .. csproj,
      "Target: " .. (target_label or "Test run"),
      "Filter: " .. (filter_expr and filter_expr or "<none>"),
      "Exit code: " .. tostring(obj.code),
    }
    if filter_mode then
      table.insert(header, "Filter mode: " .. filter_mode)
    end
    if filter_note then
      table.insert(header, "Note: " .. filter_note)
    end

    local buf = ensure_results_buf()
    set_results_content(buf, header, combined)
    open_results_split(buf)

    if obj.code == 0 then
      notify(vim.log.levels.INFO, "Tests passed")
    else
      notify(vim.log.levels.WARN, "Tests failed")
      set_quickfix_from_trx(trx_path)
    end
  end)
end

function M.run_nearest_test()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    notify(vim.log.levels.WARN, "No file name for current buffer")
    return
  end

  -- Use the LSP to get symbols for the current buffer.
  local cursor = vim.api.nvim_win_get_cursor(0)
  local pos = { line = cursor[1] - 1, character = cursor[2] }

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
    if err then
      notify(vim.log.levels.ERROR, "LSP documentSymbol error: " .. err.message)
      return
    end
    if not result or vim.tbl_isempty(result) then
      notify(vim.log.levels.WARN, "No symbols from LSP")
      return
    end

    -- Resolve the method symbol containing the cursor.
    local method_info
    if result[1].range then
      method_info = find_method_in_document_symbols(result, pos)
    else
      method_info = find_method_in_symbol_info(result, pos)
    end

    if not method_info then
      notify(vim.log.levels.WARN, "No method found at cursor")
      return
    end

    local method_symbol = method_info.symbol
    local method_range = method_symbol.range or (method_symbol.location and method_symbol.location.range)
    if not method_range then
      notify(vim.log.levels.WARN, "No range for method symbol")
      return
    end

    -- Confirm the method is a test by scanning attributes above it.
    if not has_test_attribute(bufnr, method_range.start.line) then
      notify(vim.log.levels.WARN, "Nearest method is not a test")
      return
    end

    -- Build FullyQualifiedName from namespace + containing types + method.
    local fqn = build_fqn(bufnr, method_info.scope, method_symbol.name)
    local filter_expr = "FullyQualifiedName=" .. fqn

    -- Locate the closest .csproj and run dotnet test.
    local csproj = find_csproj(vim.fs.dirname(bufname))
    if not csproj then
      notify(vim.log.levels.ERROR, "No .csproj found for current file")
      return
    end

    run_dotnet_test(csproj, filter_expr, "Test: " .. fqn, "exact", nil)
  end)
end

function M.run_test_in_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    notify(vim.log.levels.WARN, "No file name for current buffer")
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
    if err then
      notify(vim.log.levels.ERROR, "LSP documentSymbol error: " .. err.message)
      return
    end
    if not result or vim.tbl_isempty(result) then
      notify(vim.log.levels.WARN, "No symbols from LSP")
      return
    end

    local tests
    if result[1].range then
      tests = collect_tests_from_document_symbols(result, bufnr)
    else
      tests = collect_tests_from_symbol_info(result, bufnr)
    end

    if not tests or vim.tbl_isempty(tests) then
      notify(vim.log.levels.WARN, "No tests found in file")
      return
    end

    local choices = {
      { label = "All tests in file", all = true },
    }
    for _, item in ipairs(tests) do
      local fqn = build_fqn(bufnr, item.scope, item.symbol.name)
      table.insert(choices, { label = fqn, fqn = fqn })
    end

    vim.ui.select(choices, {
      prompt = "Select test",
      format_item = function(item)
        return item.label
      end,
    }, function(selected)
      if not selected then
        return
      end

      local csproj = find_csproj(vim.fs.dirname(bufname))
      if not csproj then
        notify(vim.log.levels.ERROR, "No .csproj found for current file")
        return
      end

      if selected.all then
        local filter_expr, mode, note = build_filter_for_tests(tests, bufnr)
        local relpath = vim.fn.fnamemodify(bufname, ":.")
        run_dotnet_test(csproj, filter_expr, "All tests in file: " .. relpath, mode, note)
      else
        local filter_expr = "FullyQualifiedName=" .. selected.fqn
        run_dotnet_test(csproj, filter_expr, "Test: " .. selected.fqn, "exact", nil)
      end
    end)
  end)
end

function M.run_all_tests_in_project()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    notify(vim.log.levels.WARN, "No file name for current buffer")
    return
  end

  local csproj = find_csproj(vim.fs.dirname(bufname))
  if not csproj then
    notify(vim.log.levels.ERROR, "No .csproj found for current file")
    return
  end

  run_project_tests(csproj, "All tests in project: " .. csproj)
end

function M.pick_project_and_run_tests(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    notify(vim.log.levels.WARN, "No file name for current buffer")
    return
  end

  local root = find_root(vim.fs.dirname(bufname))
  if not root then
    notify(vim.log.levels.WARN, "No solution or git root found")
    return
  end

  local refresh = opts and opts.refresh or false
  local projects = get_cached_test_projects(root, refresh)
  if not projects or #projects == 0 then
    notify(vim.log.levels.WARN, "No test projects found")
    return
  end

  local choices = {
    { label = "All test projects", all = true },
    { label = "Refresh projects", refresh = true },
  }
  for _, csproj in ipairs(projects) do
    local rel = relpath_from_root(root, csproj)
    table.insert(choices, { label = rel, csproj = csproj })
  end

  vim.ui.select(choices, {
    prompt = "Select test project",
    format_item = function(item)
      return item.label
    end,
  }, function(selected)
    if not selected then
      return
    end

    if selected.refresh then
      state.test_projects_by_root[root] = nil
      vim.schedule(function()
        M.pick_project_and_run_tests({ refresh = true })
      end)
      return
    end

    if selected.all then
      run_multiple_projects(projects, root)
      return
    end

    run_project_tests(selected.csproj, "All tests in project: " .. selected.csproj)
  end)
end

pcall(vim.api.nvim_create_user_command, "DotnetTestProject", function()
  require("dotnet_tests").run_all_tests_in_project()
end, { desc = "Run all .NET tests in the current project" })

pcall(vim.api.nvim_create_user_command, "DotnetTestPickProject", function()
  require("dotnet_tests").pick_project_and_run_tests()
end, { desc = "Pick a test project to run" })

-- Example keymap:
-- vim.keymap.set("n", "<leader>dp", function()
--   require("dotnet_tests").run_all_tests_in_project()
-- end, { desc = "Run all tests in project" })

return M
