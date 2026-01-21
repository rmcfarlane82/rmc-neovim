local M = {}

local SymbolKind = vim.lsp.protocol.SymbolKind

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

-- Find the closest .csproj by walking upward from the current file directory.
local function find_csproj(start_dir)
  local matches = vim.fs.find(function(name)
    return name:match("%.csproj$")
  end, { path = start_dir, upward = true, type = "file", limit = 1 })
  return matches[1]
end

local function ensure_results_buf()
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

local function open_results_split(bufnr)
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

local function set_results_content(bufnr, header_lines, output)
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

-- Run dotnet test with a FullyQualifiedName filter.
local function run_dotnet_test(csproj, fqn)
  local cmd = {
    "dotnet",
    "test",
    csproj,
    "--filter",
    "FullyQualifiedName=" .. fqn,
    "--no-build",
  }

  notify(vim.log.levels.INFO, "Running .NET tests...")

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      local stdout = obj.stdout or ""
      local stderr = obj.stderr or ""
      local combined = stdout
      if stderr ~= "" then
        combined = combined .. "\n" .. stderr
      end

      local header = {
        "Dotnet test results",
        "Time: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "Project: " .. csproj,
        "Filter: FullyQualifiedName=" .. fqn,
        "Exit code: " .. tostring(obj.code),
      }

      local buf = ensure_results_buf()
      set_results_content(buf, header, combined)
      open_results_split(buf)

      if obj.code == 0 then
        notify(vim.log.levels.INFO, "Tests passed")
      else
        notify(vim.log.levels.WARN, "Tests failed")
        set_quickfix_from_output(combined)
      end
    end)
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

    -- Locate the closest .csproj and run dotnet test.
    local csproj = find_csproj(vim.fs.dirname(bufname))
    if not csproj then
      notify(vim.log.levels.ERROR, "No .csproj found for current file")
      return
    end

    run_dotnet_test(csproj, fqn)
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

    local choices = {}
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

      run_dotnet_test(csproj, selected.fqn)
    end)
  end)
end

return M
