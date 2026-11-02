local config = require 'ask.config'
local context = require 'ask.context'
local input = require 'ask.input'
local thread_mod = require 'ask.thread'
local view = require 'ask.view'

local M = {}

local DEFAULT_QUESTION = 'Explain this code.'

local profile_index = 1

thread_mod.on_change = view.refresh

--- Starts a new thread about the visual selection. Call it while still in visual mode.
function M.ask()
  local ctx = context.capture()
  if #ctx.text > config.max_selection_bytes then
    vim.notify(('Ask: the selection is too large (%d KiB, limit %d KiB)'):format(#ctx.text / 1024, config.max_selection_bytes / 1024), vim.log.levels.WARN)
    return
  end

  local location = context.location(ctx)

  input.open {
    title = function() return (' Ask · %s · %s '):format(config.profiles[profile_index].name, location) end,
    footer = ' <CR> send  <C-j> newline  <Tab> profile  <Esc><Esc> close ',
    on_cycle = function() profile_index = profile_index % #config.profiles + 1 end,
    on_submit = function(text)
      local question = text ~= '' and text or DEFAULT_QUESTION
      local title = vim.split(question, '\n', { plain = true })[1]
      if text == '' then title = 'Explain ' .. location end

      local thread = thread_mod.new(config.profiles[profile_index], ctx.root, title)
      view.setup_buffer(thread)
      view.show(thread)

      local shown = { '`' .. location .. '`' }
      vim.list_extend(shown, vim.split(question, '\n', { plain = true }))
      thread_mod.ask(thread, shown, context.prompt(ctx, question))
    end,
  }
end

--- Asks another question in a thread's existing session.
function M.follow_up(thread)
  if thread.run then
    vim.notify('Ask: this thread is still running. Press <C-c> to stop it.', vim.log.levels.WARN)
    return
  end

  input.open {
    title = function() return (' Follow up · %s '):format(thread.profile.name) end,
    footer = ' <CR> send  <C-j> newline  <Esc><Esc> close ',
    on_submit = function(text)
      if text == '' then return end
      -- The fixed opening stops a question starting with `-` or `@` being read as a flag or file by the harness.
      thread_mod.ask(thread, vim.split(text, '\n', { plain = true }), 'Follow-up question:\n' .. text)
    end,
  }
end

function M.pick()
  if #thread_mod.threads == 0 then
    vim.notify 'Ask: no threads yet. Select some code and press <leader>?'
    return
  end
  require 'ask.picker'(thread_mod.threads, view.show)
end

return M
