local M = {}

local SymbolKind = vim.lsp.protocol.SymbolKind

local state = {
  test_projects_by_root = {},
  index = {},
  explorer = {
    expanded_nodes = {},
    line_map = {},
    root = nil,
    projects = {},
    bufnr = nil,
  },
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
local open_test_explorer

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

local function build_filter_for_fqns(fqns, class_fqn)
  local max_len = 1500
  local filters = {}
  for _, fqn in ipairs(fqns) do
    table.insert(filters, "FullyQualifiedName=" .. fqn)
  end

  local exact = table.concat(filters, "|")
  if #exact <= max_len then
    return exact, "exact", nil
  end

  if class_fqn and class_fqn ~= "" then
    return "FullyQualifiedName~" .. class_fqn, "class", "Filter too long; using class-level filter"
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

local function find_cs_files(project_dir)
  local excluded = {
    "/bin/",
    "/obj/",
    "/.git/",
    "/.vs/",
    "/packages/",
    "\\bin\\",
    "\\obj\\",
    "\\.git\\",
    "\\.vs\\",
    "\\packages\\",
  }

  local matches = vim.fs.find(function(name, path)
    if not name:match("%.cs$") then
      return false
    end
    for _, needle in ipairs(excluded) do
      if path:find(needle, 1, true) then
        return false
      end
    end
    return true
  end, { path = project_dir, type = "file", limit = math.huge })

  table.sort(matches)
  return matches
end

local function get_file_mtime(file_path)
  local uv = vim.uv or vim.loop
  local stat = uv.fs_stat(file_path)
  if not stat then
    return nil
  end
  if type(stat.mtime) == "table" then
    return stat.mtime.sec or stat.mtime.nsec
  end
  return stat.mtime
end

local function strip_line_comments(line)
  local trimmed = line:gsub("//.*", "")
  return trimmed
end

local function parse_tests_from_file(file_path, csproj)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return {}
  end

  local tests = {}
  local namespace
  local namespace_depth
  local class_stack = {}
  local pending_class
  local pending_attr = false
  local in_block_comment = false
  local brace_depth = 0

  local function count_char(str, ch)
    local _, count = str:gsub(ch, "")
    return count
  end

  local function current_class_fqn()
    if #class_stack == 0 then
      return ""
    end
    local parts = {}
    for _, item in ipairs(class_stack) do
      table.insert(parts, item.name)
    end
    return table.concat(parts, ".")
  end

  local function build_fqn(ns, class_fqn, method)
    local parts = {}
    if ns and ns ~= "" then
      table.insert(parts, ns)
    end
    if class_fqn and class_fqn ~= "" then
      table.insert(parts, class_fqn)
    end
    table.insert(parts, method)
    return table.concat(parts, ".")
  end

  local function is_test_attribute(line)
    for _, attr in ipairs(test_attributes) do
      local pattern = "%f[%w_]" .. attr .. "%f[^%w_]"
      if line:match(pattern) then
        return true
      end
    end
    return false
  end

  local function is_method_candidate(name)
    local keywords = {
      ["if"] = true,
      ["for"] = true,
      ["foreach"] = true,
      ["while"] = true,
      ["switch"] = true,
      ["catch"] = true,
      ["using"] = true,
      ["return"] = true,
      ["new"] = true,
      ["lock"] = true,
    }
    return name and not keywords[name]
  end

  for i, raw in ipairs(lines) do
    local line = raw
    if in_block_comment then
      local end_pos = line:find("%*/")
      if end_pos then
        line = line:sub(end_pos + 2)
        in_block_comment = false
      else
        goto continue
      end
    end

    local block_start = line:find("/%*")
    if block_start then
      local before = line:sub(1, block_start - 1)
      local after = line:sub(block_start + 2)
      local block_end = after:find("%*/")
      if block_end then
        line = before .. after:sub(block_end + 2)
      else
        line = before
        in_block_comment = true
      end
    end

    line = strip_line_comments(line)
    local trimmed = vim.trim(line)
    local ns = trimmed:match("^namespace%s+([%w%._]+)%s*[;{]")
    if ns then
      namespace = ns
      if trimmed:find("{", 1, true) then
        namespace_depth = brace_depth + 1
      else
        namespace_depth = nil
      end
    end

    if pending_class and trimmed:find("{", 1, true) then
      table.insert(class_stack, { name = pending_class, depth = brace_depth + 1 })
      pending_class = nil
    end

    local class_name = trimmed:match("%f[%w_]class%s+([%w_]+)")
    if class_name then
      if trimmed:find("{", 1, true) then
        table.insert(class_stack, { name = class_name, depth = brace_depth + 1 })
      else
        pending_class = class_name
      end
    end

    if trimmed:match("^%[") then
      if is_test_attribute(trimmed) then
        pending_attr = true
        if trimmed:find("%]", 1, true) and trimmed:find("%(", 1, true) then
          local method_name
          for name in trimmed:gmatch("([%w_]+)%s*%(") do
            method_name = name
          end
          if is_method_candidate(method_name) then
            local class_fqn = current_class_fqn()
            if class_fqn ~= "" then
              local fqn = build_fqn(namespace or "", class_fqn, method_name)
              table.insert(tests, {
                name = method_name,
                fqn = fqn,
                namespace = namespace or "",
                class = class_fqn,
                path = file_path,
                line = i,
                csproj = csproj,
              })
            end
            pending_attr = false
          end
        end
      end
    elseif pending_attr and trimmed ~= "" then
      local method_name
      for name in trimmed:gmatch("([%w_]+)%s*%(") do
        method_name = name
      end

      if is_method_candidate(method_name) then
        local class_fqn = current_class_fqn()
        if class_fqn ~= "" then
          local fqn = build_fqn(namespace or "", class_fqn, method_name)
          table.insert(tests, {
            name = method_name,
            fqn = fqn,
            namespace = namespace or "",
            class = class_fqn,
            path = file_path,
            line = i,
            csproj = csproj,
          })
        end
        pending_attr = false
      else
        pending_attr = false
      end
    elseif trimmed ~= "" then
      pending_attr = false
    end

    local opens = count_char(line, "{")
    local closes = count_char(line, "}")
    brace_depth = brace_depth + opens - closes

    while #class_stack > 0 and brace_depth < class_stack[#class_stack].depth do
      table.remove(class_stack)
    end

    if namespace_depth and brace_depth < namespace_depth then
      namespace = nil
      namespace_depth = nil
    end

    ::continue::
  end

  return tests
end

local function ensure_explorer_buf()
  local name = "Dotnet Test Explorer"
  local existing = vim.fn.bufnr(name)
  if existing > 0 then
    state.explorer.bufnr = existing
    vim.bo[existing].buflisted = false
    vim.bo[existing].buftype = "nofile"
    vim.bo[existing].swapfile = false
    vim.bo[existing].modifiable = false
    vim.bo[existing].filetype = "dotnettestexplorer"
    return existing
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "dotnettestexplorer"
  state.explorer.bufnr = buf
  return buf
end

local function open_explorer_split(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd("botright vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)
end

local function ensure_project_index(root, csproj)
  state.index[root] = state.index[root] or {}
  local entry = state.index[root][csproj]
  if not entry then
    entry = {
      files_total = 0,
      files_indexed = 0,
      is_indexing = false,
      tests_by_file = {},
      pending_files = {},
      batch_scheduled = false,
    }
    state.index[root][csproj] = entry
  end
  return entry
end

local function build_project_tree(root, csproj)
  local entry = ensure_project_index(root, csproj)
  local namespaces = {}
  local total = 0

  for _, file_entry in pairs(entry.tests_by_file) do
    for _, test in ipairs(file_entry.tests or {}) do
      total = total + 1
      local ns = test.namespace or ""
      local ns_node = namespaces[ns]
      if not ns_node then
        ns_node = { name = ns, classes = {}, count = 0 }
        namespaces[ns] = ns_node
      end
      ns_node.count = ns_node.count + 1

      local class_name = test.class or ""
      local class_node = ns_node.classes[class_name]
      if not class_node then
        class_node = { name = class_name, tests = {}, count = 0 }
        ns_node.classes[class_name] = class_node
      end
      class_node.count = class_node.count + 1
      table.insert(class_node.tests, test)
    end
  end

  local namespace_list = {}
  for _, ns_node in pairs(namespaces) do
    local class_list = {}
    for _, class_node in pairs(ns_node.classes) do
      table.sort(class_node.tests, function(a, b)
        if a.path == b.path then
          if a.line == b.line then
            return a.name < b.name
          end
          return a.line < b.line
        end
        return a.path < b.path
      end)
      table.insert(class_list, class_node)
    end
    table.sort(class_list, function(a, b)
      return a.name < b.name
    end)
    ns_node.class_list = class_list
    table.insert(namespace_list, ns_node)
  end
  table.sort(namespace_list, function(a, b)
    return a.name < b.name
  end)

  return total, namespace_list, entry
end

local function node_key(kind, csproj, namespace, class_name)
  if kind == "project" then
    return "project:" .. csproj
  end
  if kind == "namespace" then
    return "namespace:" .. csproj .. ":" .. (namespace or "")
  end
  if kind == "class" then
    return "class:" .. csproj .. ":" .. (namespace or "") .. ":" .. (class_name or "")
  end
  return ""
end

local function node_expanded(key)
  local expanded = state.explorer.expanded_nodes[key]
  if expanded == nil then
    return true
  end
  return expanded
end

local function render_explorer()
  local bufnr = state.explorer.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local root = state.explorer.root
  local projects = state.explorer.projects or {}
  local lines = {}
  local line_map = {}

  table.insert(lines, "Dotnet Test Explorer")
  if root then
    table.insert(lines, "Root: " .. root)
  end
  table.insert(lines, "Projects: " .. tostring(#projects))

  local indexing_projects = 0
  for _, csproj in ipairs(projects) do
    local entry = ensure_project_index(root, csproj)
    if entry.is_indexing then
      indexing_projects = indexing_projects + 1
    end
  end
  if indexing_projects > 0 then
    table.insert(lines, "Indexing: " .. tostring(indexing_projects) .. " project(s)")
  else
    table.insert(lines, "Indexing: idle")
  end
  table.insert(lines, "")

  if not projects or #projects == 0 then
    table.insert(lines, "No test projects found")
  else
    for _, csproj in ipairs(projects) do
      local total, namespaces, entry = build_project_tree(root, csproj)
      local key = node_key("project", csproj)
      local expanded = node_expanded(key)
      local icon = expanded and "▾" or "▸"
      local label = relpath_from_root(root, csproj)
      table.insert(lines, icon .. " " .. label .. " (" .. tostring(total) .. ")")
      line_map[#lines] = { type = "project", csproj = csproj, key = key }

      if entry.is_indexing then
        local progress = string.format("  Indexing... (%d/%d)", entry.files_indexed, entry.files_total)
        table.insert(lines, progress)
      end

      if expanded then
        for _, ns_node in ipairs(namespaces) do
          local ns_label = ns_node.name ~= "" and ns_node.name or "(global)"
          table.insert(lines, "  " .. ns_label .. " (" .. tostring(ns_node.count) .. ")")
          line_map[#lines] = {
            type = "namespace",
            csproj = csproj,
            namespace = ns_node.name,
          }

          for _, class_node in ipairs(ns_node.class_list) do
            local class_label = class_node.name ~= "" and class_node.name or "(anonymous)"
            table.insert(lines, "    " .. class_label .. " (" .. tostring(class_node.count) .. ")")
            local class_fqn = class_node.name
            if ns_node.name and ns_node.name ~= "" then
              class_fqn = ns_node.name .. "." .. class_node.name
            end
            line_map[#lines] = {
              type = "class",
              csproj = csproj,
              namespace = ns_node.name,
              class = class_node.name,
              class_fqn = class_fqn,
              fqns = vim.tbl_map(function(test)
                return test.fqn
              end, class_node.tests),
            }

            for _, test in ipairs(class_node.tests) do
              local rel = relpath_from_root(vim.fs.dirname(csproj), test.path)
              local entry_line = string.format("      %s:%d  %s", rel, test.line, test.name)
              table.insert(lines, entry_line)
              line_map[#lines] = {
                type = "test",
                csproj = csproj,
                fqn = test.fqn,
                path = test.path,
                line = test.line,
              }
            end
          end
        end
      end
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  state.explorer.line_map = line_map
end

local function schedule_index_batch(root, csproj)
  local entry = ensure_project_index(root, csproj)
  if entry.batch_scheduled then
    return
  end

  entry.batch_scheduled = true
  vim.schedule(function()
    local batch_size = 50
    local pending = entry.pending_files or {}
    local count = math.min(batch_size, #pending)

    for _ = 1, count do
      local file_path = table.remove(pending, 1)
      if file_path then
        local mtime = get_file_mtime(file_path)
        if mtime then
          local tests = parse_tests_from_file(file_path, csproj)
          entry.tests_by_file[file_path] = { mtime = mtime, tests = tests }
        else
          entry.tests_by_file[file_path] = nil
        end
        entry.files_indexed = entry.files_indexed + 1
      end
    end

    entry.pending_files = pending
    if #pending > 0 then
      entry.batch_scheduled = false
      schedule_index_batch(root, csproj)
    else
      entry.is_indexing = false
      entry.batch_scheduled = false
    end

    render_explorer()
  end)
end

local function index_test_projects(root, opts)
  local rebuild_cache = opts and opts.rebuild_cache or false
  if rebuild_cache then
    state.index[root] = {}
  end

  state.explorer.root = root
  local projects = get_cached_test_projects(root, rebuild_cache)
  state.explorer.projects = projects

  for _, csproj in ipairs(projects) do
    local entry = ensure_project_index(root, csproj)
    if rebuild_cache then
      entry.tests_by_file = {}
    end

    local project_dir = vim.fs.dirname(csproj)
    local files = find_cs_files(project_dir)
    local file_set = {}
    for _, file_path in ipairs(files) do
      file_set[file_path] = true
    end
    for file_path in pairs(entry.tests_by_file) do
      if not file_set[file_path] then
        entry.tests_by_file[file_path] = nil
      end
    end

    local pending = {}
    for _, file_path in ipairs(files) do
      local mtime = get_file_mtime(file_path)
      local cached = entry.tests_by_file[file_path]
      if rebuild_cache or not cached or cached.mtime ~= mtime then
        table.insert(pending, file_path)
      end
    end

    entry.files_total = #files
    entry.files_indexed = #files - #pending
    entry.pending_files = pending
    entry.is_indexing = #pending > 0

    if entry.is_indexing then
      schedule_index_batch(root, csproj)
    end
  end

  render_explorer()
end

local function refresh_test_index()
  local root = state.explorer.root
  if not root then
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname ~= "" and vim.bo[bufnr].buftype ~= "nofile" then
      root = find_root(vim.fs.dirname(bufname))
      state.explorer.root = root
    end
  end
  if not root then
    notify(vim.log.levels.WARN, "No root for test explorer")
    return
  end
  index_test_projects(root, { rebuild_cache = false })
end

local function rebuild_test_index()
  local root = state.explorer.root
  if not root then
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname ~= "" and vim.bo[bufnr].buftype ~= "nofile" then
      root = find_root(vim.fs.dirname(bufname))
      state.explorer.root = root
    end
  end
  if not root then
    notify(vim.log.levels.WARN, "No root for test explorer")
    return
  end
  index_test_projects(root, { rebuild_cache = true })
end

local function open_file_at_line(path, line)
  local explorer_buf = state.explorer.bufnr
  local target_win
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) ~= explorer_buf then
      target_win = win
      break
    end
  end
  if not target_win then
    target_win = vim.api.nvim_get_current_win()
  end

  vim.api.nvim_set_current_win(target_win)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(target_win, { line, 0 })
end

local function handle_explorer_enter()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local node = state.explorer.line_map[line]
  if not node then
    return
  end

  if node.type == "project" then
    local key = node_key("project", node.csproj)
    local expanded = node_expanded(key)
    state.explorer.expanded_nodes[key] = not expanded
    render_explorer()
    return
  end

  if node.type == "namespace" then
    local namespace = node.namespace or ""
    if namespace == "" then
      run_project_tests(node.csproj, "Namespace: (global)")
    else
      local filter_expr = "FullyQualifiedName~" .. namespace
      run_dotnet_test(node.csproj, filter_expr, "Namespace: " .. namespace, "namespace", nil)
    end
    return
  end

  if node.type == "class" then
    local filter_expr, mode, note = build_filter_for_fqns(node.fqns or {}, node.class_fqn)
    local label = "Class: " .. (node.class_fqn ~= "" and node.class_fqn or node.class or "(anonymous)")
    run_dotnet_test(node.csproj, filter_expr, label, mode, note)
    return
  end

  if node.type == "test" then
    local filter_expr = "FullyQualifiedName=" .. node.fqn
    run_dotnet_test(node.csproj, filter_expr, "Test: " .. node.fqn, "exact", nil)
  end
end

local function handle_explorer_open()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local node = state.explorer.line_map[line]
  if not node or node.type ~= "test" then
    return
  end
  open_file_at_line(node.path, node.line)
end

local function setup_explorer_keymaps(bufnr)
  vim.keymap.set("n", "<CR>", handle_explorer_enter, { buffer = bufnr, nowait = true })
  vim.keymap.set("n", "o", handle_explorer_open, { buffer = bufnr, nowait = true })
  vim.keymap.set("n", "r", function()
    refresh_test_index()
  end, { buffer = bufnr, nowait = true })
  vim.keymap.set("n", "R", function()
    rebuild_test_index()
  end, { buffer = bufnr, nowait = true })
  vim.keymap.set("n", "q", function()
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = bufnr, nowait = true })
end

open_test_explorer = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local root
  if bufname == "" or vim.bo[bufnr].buftype == "nofile" then
    root = state.explorer.root
  else
    root = find_root(vim.fs.dirname(bufname))
  end

  if not root then
    notify(vim.log.levels.WARN, "No solution or git root found")
    return
  end

  state.explorer.root = root
  local explorer_buf = ensure_explorer_buf()
  open_explorer_split(explorer_buf)
  setup_explorer_keymaps(explorer_buf)
  index_test_projects(root, { rebuild_cache = false })
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

function M.open_test_explorer()
  open_test_explorer()
end

function M.index_test_projects(root, opts)
  index_test_projects(root, opts)
end

function M.refresh_test_index()
  refresh_test_index()
end

function M.rebuild_test_index()
  rebuild_test_index()
end

pcall(vim.api.nvim_create_user_command, "DotnetTestProject", function()
  require("dotnet_tests").run_all_tests_in_project()
end, { desc = "Run all .NET tests in the current project" })

pcall(vim.api.nvim_create_user_command, "DotnetTestPickProject", function()
  require("dotnet_tests").pick_project_and_run_tests()
end, { desc = "Pick a test project to run" })

pcall(vim.api.nvim_create_user_command, "DotnetTestExplorer", function()
  require("dotnet_tests").open_test_explorer()
end, { desc = "Open Dotnet Test Explorer" })

pcall(vim.api.nvim_create_user_command, "DotnetTestIndexRefresh", function()
  require("dotnet_tests").refresh_test_index()
end, { desc = "Refresh Dotnet test index" })

pcall(vim.api.nvim_create_user_command, "DotnetTestIndexRebuild", function()
  require("dotnet_tests").rebuild_test_index()
end, { desc = "Rebuild Dotnet test index" })

-- Example keymap:
-- vim.keymap.set("n", "<leader>dp", function()
--   require("dotnet_tests").run_all_tests_in_project()
-- end, { desc = "Run all tests in project" })

return M
