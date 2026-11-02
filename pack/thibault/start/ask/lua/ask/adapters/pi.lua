-- See adapters/claude.lua for the adapter contract.
local tool_line = require 'ask.tool_line'

local M = {}

function M.command(opts)
  -- --session-id creates the session on the first run and resumes it afterwards, so opts.resume isn't needed.
  -- `pi --help` lists no permission prompts, so there is no equivalent of Claude's bypass flag to pass.
  local cmd = { 'pi', '-p', '--mode', 'json', '--session-id', opts.session_id, '--model', opts.model, '--append-system-prompt', opts.system_prompt }
  if opts.thinking then vim.list_extend(cmd, { '--thinking', opts.thinking }) end
  cmd[#cmd + 1] = opts.prompt
  return cmd
end

function M.new_parser(cwd)
  return function(event)
    if event.type == 'session' then return { { type = 'session' } } end

    if event.type == 'message_update' then
      local update = event.assistantMessageEvent or {}
      if update.type == 'text_start' then return { { type = 'text_start' } } end
      if update.type == 'text_delta' then return { { type = 'text', text = update.delta } } end
    elseif event.type == 'tool_execution_start' then
      return { { type = 'tool', line = tool_line(event.toolName, event.args, cwd) } }
    elseif event.type == 'message_end' then
      -- pi exits 0 even when the model call fails, so this event is the only sign of an error.
      local message = event.message or {}
      if message.role == 'assistant' and message.stopReason == 'error' then
        return { { type = 'error', message = message.errorMessage or 'model call failed' } }
      end
    end

    return {}
  end
end

return M
