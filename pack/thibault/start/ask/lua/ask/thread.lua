-- A thread owns one answer buffer and one harness session, and runs the harness for each question.
local config = require 'ask.config'

local M = {}

---@type table[] newest first
M.threads = {}
--- Called whenever a thread's status changes.
M.on_change = function(_) end

local ns = vim.api.nvim_create_namespace 'ask'

local function new_session_id()
  local b = { vim.uv.random(16):byte(1, 16) }
  b[7] = bit.bor(bit.band(b[7], 0x0f), 0x40)
  b[9] = bit.bor(bit.band(b[9], 0x3f), 0x80)
  return ('%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x'):format(unpack(b))
end

--- herdr would otherwise treat each background agent as the agent running in nvim's pane.
local function harness_env()
  local env = vim.fn.environ()
  for name in pairs(env) do
    if name:match '^HERDR_' then env[name] = nil end
  end
  return env
end

--- Runs `write` on the read-only buffer, keeping windows at the bottom scrolled to the bottom.
local function edit(thread, write)
  local buf = thread.buf
  if not vim.api.nvim_buf_is_loaded(buf) then return end

  local last = vim.api.nvim_buf_line_count(buf)
  local following = vim.tbl_filter(function(win) return vim.api.nvim_win_get_cursor(win)[1] == last end, vim.fn.win_findbuf(buf))

  vim.bo[buf].modifiable = true
  write(buf)
  vim.bo[buf].modifiable = false

  local count = vim.api.nvim_buf_line_count(buf)
  for _, win in ipairs(following) do
    vim.api.nvim_win_set_cursor(win, { count, 0 })
  end
end

local function append_text(thread, text)
  edit(thread, function(buf)
    local parts = vim.split(text, '\n', { plain = true })
    parts[1] = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1] .. parts[1]
    vim.api.nvim_buf_set_lines(buf, -2, -1, false, parts)
  end)
end

--- Writes whole lines after a blank line, and leaves an empty last line for streaming into.
local function append_block(thread, lines, hl_group)
  edit(thread, function(buf)
    local count = vim.api.nvim_buf_line_count(buf)
    local last_is_empty = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1] == ''
    local is_empty_buffer = count == 1 and last_is_empty

    local block = last_is_empty and {} or { '' }
    vim.list_extend(block, lines)
    block[#block + 1] = ''

    local from = is_empty_buffer and 0 or count
    vim.api.nvim_buf_set_lines(buf, from, count, false, block)

    if hl_group then
      local first_row = last_is_empty and from or from + 1
      for row = first_row, first_row + #lines - 1 do
        vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_row = row + 1, hl_group = hl_group, priority = 200 })
      end
    end
  end)
end

local function write_tool(thread, run, line)
  if run.last == 'text' then
    append_block(thread, { line }, 'Comment')
  else
    edit(thread, function(buf)
      local row = vim.api.nvim_buf_line_count(buf) - 1
      vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { line, '' })
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_row = row + 1, hl_group = 'Comment', priority = 200 })
    end)
  end
  run.last = 'tool'
end

local function write_text(thread, run, text)
  if run.last == 'tool' then append_text(thread, '\n') end
  run.last = 'text'
  run.answered = true
  run.failed = false
  append_text(thread, text)
end

local function write_error(thread, run, message)
  append_block(thread, vim.split('Error: ' .. message, '\n', { plain = true }), 'DiagnosticError')
  run.last = 'error'
  run.failed = true
end

local function handle_event(thread, run, parse, json)
  local ok, event = pcall(vim.json.decode, json, { luanil = { object = true, array = true } })
  if not ok or type(event) ~= 'table' then return end

  for _, item in ipairs(parse(event)) do
    if item.type == 'session' then
      thread.session_started = true
    elseif item.type == 'text_start' then
      if run.last == 'text' then append_text(thread, '\n\n') end
    elseif item.type == 'text' then
      write_text(thread, run, item.text)
    elseif item.type == 'tool' then
      run.answered = true
      write_tool(thread, run, item.line)
    elseif item.type == 'error' then
      write_error(thread, run, item.message)
    end
  end
end

--- Picks up edits the agent made, without touching buffers that have unsaved changes.
local function reload_edited_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and not vim.bo[buf].modified then pcall(vim.cmd.checktime, tostring(buf)) end
  end
end

local function set_status(thread, status)
  thread.status = status
  M.on_change(thread)
end

local function finish(thread, run, code)
  thread.run = nil

  if run.stopped then
    append_block(thread, { 'Stopped.' }, 'DiagnosticWarn')
    set_status(thread, 'stopped')
  else
    if not run.failed and code ~= 0 then
      write_error(thread, run, ('%s exited with code %d\n%s'):format(thread.profile.adapter, code, table.concat(run.stderr, '\n')))
    elseif not run.failed and not run.answered then
      write_error(thread, run, thread.profile.adapter .. ' finished without an answer\n' .. table.concat(run.stderr, '\n'))
    end
    set_status(thread, run.failed and 'error' or 'done')
  end

  reload_edited_buffers()
  if thread.status ~= 'stopped' and #vim.fn.win_findbuf(thread.buf) == 0 and vim.api.nvim_buf_is_loaded(thread.buf) then
    local failed = thread.status == 'error'
    vim.notify(('Ask: "%s" %s'):format(thread.title, failed and 'failed' or 'finished'), failed and vim.log.levels.ERROR or vim.log.levels.INFO)
  end
end

--- Sends one prompt to the thread's session.
function M.start(thread, prompt)
  local adapter = require('ask.adapters.' .. thread.profile.adapter)
  if not thread.session_started then thread.session_id = new_session_id() end

  local parse = adapter.new_parser(thread.root)
  local run = { stderr = {}, partial = '', last = 'header' }
  thread.run = run
  set_status(thread, 'running')

  local function on_stdout(_, data)
    data[1] = run.partial .. data[1]
    run.partial = table.remove(data)
    for _, line in ipairs(data) do
      handle_event(thread, run, parse, line)
    end
  end

  local function on_stderr(_, data)
    for _, line in ipairs(data) do
      if line ~= '' then run.stderr[#run.stderr + 1] = line end
    end
    while #run.stderr > 20 do
      table.remove(run.stderr, 1)
    end
  end

  local function on_exit(_, code)
    if run.partial ~= '' then handle_event(thread, run, parse, run.partial) end
    finish(thread, run, code)
  end

  local cmd = adapter.command {
    model = thread.profile.model,
    thinking = thread.profile.thinking,
    session_id = thread.session_id,
    resume = thread.session_started,
    system_prompt = config.system_prompt,
    prompt = prompt,
  }

  local ok, job = pcall(vim.fn.jobstart, cmd, {
    cwd = thread.root,
    env = harness_env(),
    clear_env = true,
    stdin = 'null',
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = on_exit,
  })
  if not ok or job <= 0 then
    thread.run = nil
    write_error(thread, run, ('could not start `%s`: %s'):format(cmd[1], ok and 'not found on $PATH' or job))
    set_status(thread, 'error')
    return
  end
  run.job = job
end

function M.stop(thread)
  if not thread.run then return end
  thread.run.stopped = true
  vim.fn.jobstop(thread.run.job)
end

--- Adds a question to the buffer and asks it. `prompt` is what the agent receives.
---@param shown string[] the lines shown under the "You" heading
function M.ask(thread, shown, prompt)
  local lines = { '## You' }
  vim.list_extend(lines, shown)
  vim.list_extend(lines, { '', '## ' .. thread.profile.name })
  append_block(thread, lines)
  M.start(thread, prompt)
end

--- Creates a thread with its hidden answer buffer.
function M.new(profile, root, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].modifiable = false
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_name(buf, ('ask://%d/%s'):format(buf, title:gsub('[^%w]+', '-'):sub(1, 40)))
  vim.bo[buf].filetype = 'markdown'

  local thread = { buf = buf, profile = profile, root = root, title = title, status = 'new' }
  table.insert(M.threads, 1, thread)

  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    once = true,
    callback = function()
      M.stop(thread)
      for i, other in ipairs(M.threads) do
        if other == thread then table.remove(M.threads, i) end
      end
    end,
  })

  return thread
end

return M
