-- The single answer split, which shows one thread's buffer at a time.
local M = {}

local answer_win

local function is_answer_win(win) return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage() end

local function is_code_win(win) return win ~= answer_win and vim.api.nvim_win_get_config(win).relative == '' end

local function winbar(thread)
  local keys = thread.run and '<C-c> stop  q close' or 'i follow up  q close'
  return ('%s · %s · %s'):format(thread.profile.name, thread.status, keys):gsub('%%', '%%%%')
end

--- Options use the window's buffer-local scope, so they don't follow other buffers into this window.
local function apply_window_options(win, thread)
  local wo = vim.wo[win][0]
  wo.wrap = true
  wo.linebreak = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = 'no'
  wo.conceallevel = 2
  wo.winbar = winbar(thread)
end

function M.show(thread)
  if not is_answer_win(answer_win) then
    vim.cmd 'botright vsplit'
    answer_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(answer_win, math.floor(vim.o.columns * 0.45))
  end
  vim.api.nvim_win_set_buf(answer_win, thread.buf)
  vim.api.nvim_set_current_win(answer_win)
  apply_window_options(answer_win, thread)
  vim.api.nvim_win_set_cursor(answer_win, { vim.api.nvim_buf_line_count(thread.buf), 0 })
end

function M.refresh(thread)
  for _, win in ipairs(vim.fn.win_findbuf(thread.buf)) do
    vim.wo[win][0].winbar = winbar(thread)
  end
end

function M.close()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.api.nvim_win_close(0, false)
  else
    vim.cmd.enew()
  end
end

--- Finds the file reference under the cursor, as `path:line` or a bare path.
local function reference_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local init = 1
  while true do
    local first, last, path, lnum = line:find('([%w_%.%-/~+@]+):(%d+)', init)
    if not first then break end
    if col >= first and col <= last then return path, tonumber(lnum) end
    init = last + 1
  end
  return vim.fn.expand '<cfile>', nil
end

--- Opens the reference under the cursor beside the answer, so the answer stays visible.
function M.jump(thread)
  local path, lnum = reference_under_cursor()
  path = vim.fn.expand(path)
  if path:sub(1, 1) ~= '/' then path = vim.fs.joinpath(thread.root, path) end
  if vim.fn.filereadable(path) == 0 then
    vim.notify('Ask: no such file: ' .. path, vim.log.levels.WARN)
    return
  end

  local previous = vim.fn.win_getid(vim.fn.winnr '#')
  local target = previous ~= 0 and is_code_win(previous) and previous or vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(is_code_win)
  if target then
    vim.api.nvim_set_current_win(target)
  else
    vim.cmd 'topleft vsplit'
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  if lnum then
    vim.api.nvim_win_set_cursor(0, { math.min(lnum, vim.api.nvim_buf_line_count(0)), 0 })
    vim.cmd.normal { args = { 'zz' }, bang = true }
  end
end

function M.setup_buffer(thread)
  local function map(lhs, fn, desc) vim.keymap.set('n', lhs, fn, { buffer = thread.buf, nowait = true, desc = desc }) end
  map('i', function() require('ask').follow_up(thread) end, 'Ask a follow-up')
  map('<C-c>', function() require('ask.thread').stop(thread) end, 'Stop this thread')
  map('q', M.close, 'Close the answer split')
  map('gF', function() M.jump(thread) end, 'Open file at line beside the answer')
  map('gf', function() M.jump(thread) end, 'Open file beside the answer')
end

return M
