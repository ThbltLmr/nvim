local M = {}

--- Reads the active visual selection and leaves visual mode.
---@return table
function M.capture()
  local anchor, cursor = vim.fn.getpos 'v', vim.fn.getpos '.'
  local text = vim.fn.getregion(anchor, cursor, { type = vim.fn.mode() })
  vim.cmd.normal { args = { vim.keycode '<Esc>' }, bang = true }

  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local is_file = vim.bo[buf].buftype == '' and name ~= ''
  local root = is_file and (vim.fs.root(buf, '.git') or vim.fs.dirname(name)) or vim.uv.cwd()

  return {
    root = root,
    file = is_file and (vim.fs.relpath(root, name) or name) or nil,
    first_line = math.min(anchor[2], cursor[2]),
    last_line = math.max(anchor[2], cursor[2]),
    lang = vim.bo[buf].filetype,
    unsaved = vim.bo[buf].modified,
    text = table.concat(text, '\n'),
  }
end

--- A short reference such as `src/parse.rs:42-47`.
function M.location(ctx)
  local lines = ctx.first_line == ctx.last_line and tostring(ctx.first_line) or (ctx.first_line .. '-' .. ctx.last_line)
  return (ctx.file or '[no file]') .. ':' .. lines
end

function M.prompt(ctx, question)
  local function attr(value) return (tostring(value):gsub('"', '&quot;')) end
  return ('<selection file="%s" lines="%d-%d" lang="%s" unsaved="%s">\n%s\n</selection>\n\n%s'):format(
    attr(ctx.file or '[no file]'),
    ctx.first_line,
    ctx.last_line,
    attr(ctx.lang),
    tostring(ctx.unsaved),
    ctx.text,
    question
  )
end

return M
