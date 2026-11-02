-- Adapter contract, shared with the other files in this directory:
--   command(opts) returns the argv for one run. opts: model, session_id, resume, system_prompt, prompt, thinking
--   new_parser(cwd) returns a function that takes one decoded JSON event and returns a list of:
--     { type = 'session' }             the harness created the session, so it can be resumed
--     { type = 'text_start' }          a new block of answer text begins
--     { type = 'text', text = '...' }  a chunk of answer text
--     { type = 'tool', line = '...' }  a tool call, formatted by ask.tool_line
--     { type = 'error', message = '...' }
local tool_line = require 'ask.tool_line'

local M = {}

function M.command(opts)
  return {
    'claude',
    '-p',
    '--output-format',
    'stream-json',
    '--verbose',
    '--include-partial-messages',
    '--permission-mode',
    'bypassPermissions',
    '--model',
    opts.model,
    opts.resume and '--resume' or '--session-id',
    opts.session_id,
    '--append-system-prompt',
    opts.system_prompt,
    opts.prompt,
  }
end

function M.new_parser(cwd)
  local seen_tools = {}

  return function(event)
    local out = {}

    if event.type == 'system' and event.subtype == 'init' then
      out[1] = { type = 'session' }
    elseif event.type == 'stream_event' and not event.parent_tool_use_id then
      -- Subagent text is skipped: it isn't part of the answer. Subagent tool calls still appear below.
      local inner = event.event or {}
      if inner.type == 'content_block_start' and (inner.content_block or {}).type == 'text' then
        out[1] = { type = 'text_start' }
      elseif inner.type == 'content_block_delta' and (inner.delta or {}).type == 'text_delta' then
        out[1] = { type = 'text', text = inner.delta.text }
      end
    elseif event.type == 'assistant' then
      -- Tool calls come from complete messages because streamed input arrives as JSON fragments.
      for _, block in ipairs((event.message or {}).content or {}) do
        if block.type == 'tool_use' and not seen_tools[block.id] then
          seen_tools[block.id] = true
          out[#out + 1] = { type = 'tool', line = tool_line(block.name, block.input, cwd) }
        end
      end
    elseif event.type == 'result' and (event.is_error or event.subtype ~= 'success') then
      local message = event.result or table.concat(event.errors or {}, '; ')
      out[1] = { type = 'error', message = message ~= '' and message or event.subtype }
    end

    return out
  end
end

return M
