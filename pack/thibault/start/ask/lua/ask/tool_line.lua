-- Turns a harness tool call into the one-line entry shown in the answer split.
local MAX_DETAIL = 120

local function one_line(value) return (tostring(value or ''):gsub('%s*\n%s*', ' ⏎ ')) end

local function shorten(value)
  local text = one_line(value)
  if vim.fn.strchars(text) <= MAX_DETAIL then return text end
  return vim.fn.strcharpart(text, 0, MAX_DETAIL) .. '…'
end

local function relative(path, cwd)
  if not path then return '' end
  return vim.fs.relpath(cwd, path) or path
end

local readers = {
  read = 'read',
  ls = 'ls',
  webfetch = 'fetch',
  fetch = 'fetch',
  websearch = 'search',
  web_search = 'search',
  task = 'agent',
  agent = 'agent',
  subagent = 'agent',
}
local editors = { edit = 'edit', multiedit = 'edit', notebookedit = 'edit', write = 'write' }

---@param name string tool name as the harness reports it
---@param input table? tool arguments
---@param cwd string directory paths are shown relative to
---@return string
return function(name, input, cwd)
  input = input or {}
  local tool = name:lower()
  local path = relative(input.file_path or input.notebook_path or input.path, cwd)

  -- Commands are never shortened: with permissions bypassed, this line is the record of what ran.
  if tool == 'bash' then return '  $ ' .. one_line(input.command) end
  if editors[tool] then return '  * ' .. editors[tool] .. ' ' .. shorten(path) end
  if tool == 'grep' then return '  > grep ' .. shorten(('"%s" %s'):format(input.pattern or '', path)) end
  if tool == 'glob' or tool == 'find' then return '  > ' .. tool .. ' ' .. shorten(input.pattern or path) end
  if readers[tool] then
    local detail = input.url or input.query or input.description or (input.queries and table.concat(input.queries, ', '))
    return '  > ' .. readers[tool] .. ' ' .. shorten(detail or path)
  end

  local ok, encoded = pcall(vim.json.encode, input)
  return '  > ' .. name .. ' ' .. shorten(ok and encoded or '')
end
