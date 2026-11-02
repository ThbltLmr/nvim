local M = {}

local MAX_HEIGHT = 10

---@param opts { title: fun(): string, footer: string, on_submit: fun(text: string), on_cycle?: fun() }
function M.open(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'askinput'
  -- Stops blink.cmp from opening a menu and claiming <Tab> and <CR> in this buffer.
  vim.b[buf].completion = false

  local width = math.min(80, vim.o.columns - 8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor(vim.o.lines * 0.25),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    title = opts.title(),
    footer = opts.footer,
  })
  vim.wo[win][0].wrap = true
  vim.wo[win][0].linebreak = true
  vim.wo[win][0].statuscolumn = "%{v:lnum == 1 ? '> ' : '  '}"

  local closed = false
  local function close()
    if closed then return end
    closed = true
    vim.cmd.stopinsert()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  local function map(modes, lhs, rhs, map_opts) vim.keymap.set(modes, lhs, rhs, vim.tbl_extend('force', { buffer = buf, nowait = true }, map_opts or {})) end

  map({ 'i', 'n' }, '<CR>', function()
    local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))
    close()
    opts.on_submit(text)
  end)
  map('i', '<C-j>', '<CR>', { noremap = true })
  map('n', '<Esc>', close)
  map({ 'i', 'n' }, '<Tab>', function()
    if not opts.on_cycle then return end
    opts.on_cycle()
    vim.api.nvim_win_set_config(win, { title = opts.title() })
  end)

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = buf,
    callback = function()
      local height = vim.api.nvim_win_text_height(win, {}).all
      vim.api.nvim_win_set_height(win, math.max(1, math.min(height, MAX_HEIGHT)))
    end,
  })
  vim.api.nvim_create_autocmd('WinLeave', { buffer = buf, once = true, callback = vim.schedule_wrap(close) })

  vim.cmd.startinsert()
end

return M
